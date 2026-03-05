module Api
  module V1
    class AgentSessionsController < ApiController
      before_action :require_agent_sessions_enabled!
      before_action :authenticate_with_api_key!
      before_action :set_agent_session, only: %i[show raw_url]
      after_action :verify_authorized, only: %i[create presign]

      def index
        @agent_sessions = @user.agent_sessions.order(updated_at: :desc)
        render json: @agent_sessions.map { |s| session_index_json(s) }
      end

      def show
        render json: session_show_json(@agent_session)
      end

      def create
        rate_limiter = @user.rate_limiter
        rate_limiter.check_limit!(:agent_session_creation)

        @agent_session = @user.agent_sessions.new(title: create_title)
        authorize @agent_session

        if params[:curated_data].present?
          create_from_curated_data
        elsif params[:normalized_data].present?
          create_from_normalized_data
        else
          create_from_content
        end
      end

      def presign
        authorize AgentSession, :create?

        unless AgentSessions::S3Storage.enabled?
          render json: { error: "S3 storage is not configured", status: 503 }, status: :service_unavailable
          return
        end

        s3_key = AgentSessions::S3Storage.generate_key(@user.id)
        presigned_url = AgentSessions::S3Storage.presigned_put_url(s3_key)

        render json: { s3_key: s3_key, presigned_url: presigned_url }
      end

      def raw_url
        unless @agent_session.s3_key.present? && AgentSessions::S3Storage.enabled?
          render json: { error: "No raw file available", status: 404 }, status: :not_found
          return
        end

        url = AgentSessions::S3Storage.presigned_get_url(@agent_session.s3_key)
        render json: { raw_url: url }
      end

      private

      def require_agent_sessions_enabled!
        return if Settings::General.enable_agent_sessions

        render json: { error: "Agent Sessions are not enabled", status: 404 }, status: :not_found
      end

      def set_agent_session
        @agent_session = if params[:id]&.match?(/\A\d+\z/)
                           @user.agent_sessions.find(params[:id])
                         else
                           @user.agent_sessions.find_by!(slug: params[:id])
                         end
      end

      def create_from_curated_data
        curated = parse_json_param(:curated_data)

        validation_errors = AgentSessionParsers::NormalizedDataValidator.validate(curated)
        if validation_errors.any?
          render json: { error: validation_errors.map(&:message).join(", "), status: 422 },
                 status: :unprocessable_entity
          return
        end

        result = AgentSessionParsers::SensitiveDataScrubber.scrub(curated)
        @agent_session.tool_name = params[:tool_name].presence || curated.dig("metadata", "tool_name") || "claude_code"
        @agent_session.curated_data = result.scrubbed_data
        @agent_session.s3_key = params[:s3_key] if params[:s3_key].present?
        @agent_session.session_metadata = result.scrubbed_data.fetch("metadata", {}).merge(
          "redactions" => result.redactions.map { |r| { "name" => r.pattern_name, "count" => r.match_count } },
        )

        save_and_respond
      rescue JSON::ParserError
        render json: { error: "Invalid JSON in curated_data", status: 422 }, status: :unprocessable_entity
      end

      def create_from_normalized_data
        normalized = parse_json_param(:normalized_data)

        validation_errors = AgentSessionParsers::NormalizedDataValidator.validate(normalized)
        if validation_errors.any?
          render json: { error: validation_errors.map(&:message).join(", "), status: 422 },
                 status: :unprocessable_entity
          return
        end

        result = AgentSessionParsers::SensitiveDataScrubber.scrub(normalized)
        @agent_session.tool_name = params[:tool_name].presence || normalized.dig("metadata", "tool_name") || "claude_code"
        @agent_session.normalized_data = result.scrubbed_data
        @agent_session.session_metadata = result.scrubbed_data.fetch("metadata", {}).merge(
          "redactions" => result.redactions.map { |r| { "name" => r.pattern_name, "count" => r.match_count } },
        )

        save_and_respond
      rescue JSON::ParserError
        render json: { error: "Invalid JSON in normalized_data", status: 422 }, status: :unprocessable_entity
      end

      def create_from_content
        content = extract_content
        unless content
          # If only s3_key is provided (CLI flow: upload to S3, create draft, curate in browser)
          if params[:s3_key].present?
            @agent_session.tool_name = params[:tool_name].presence || "claude_code"
            @agent_session.s3_key = params[:s3_key]
            save_and_respond
            return
          end

          render json: { error: "Missing session content. Provide 'curated_data', 'normalized_data', 'body', 's3_key', or 'session_file'.",
                         status: 422 }, status: :unprocessable_entity
          return
        end

        unless content.valid_encoding?
          render json: { error: "File must be valid UTF-8 text", status: 422 }, status: :unprocessable_entity
          return
        end

        if content.include?("\x00")
          render json: { error: "Binary files are not supported", status: 422 }, status: :unprocessable_entity
          return
        end

        if content.bytesize > AgentSession::MAX_RAW_DATA_SIZE
          render json: { error: "Content too large (max 10MB)", status: 422 }, status: :unprocessable_entity
          return
        end

        tool_name = params[:tool_name].presence
        if tool_name.blank? || tool_name == "auto"
          file = params[:session_file]
          filename = file.respond_to?(:original_filename) ? file.original_filename : nil
          detected_tool = AgentSessionParsers::AutoDetect.detect_tool(content, filename: filename)
          @agent_session.parse_and_normalize!(content, detected_tool: detected_tool)
        else
          @agent_session.tool_name = tool_name
          @agent_session.parse_and_normalize!(content)
        end

        save_and_respond
      rescue AgentSessionParsers::ParseError => e
        Rails.logger.error("Agent session API parse error: #{e.class}: #{e.message}")
        render json: { error: "Failed to parse session content. Please check the format and try again.", status: 422 },
               status: :unprocessable_entity
      end

      def save_and_respond
        if @agent_session.save
          @user.rate_limiter.track_limit_by_action(:agent_session_creation)
          render json: session_create_json(@agent_session), status: :created
        else
          render json: { error: @agent_session.errors.full_messages.join(", "), status: 422 },
                 status: :unprocessable_entity
        end
      end

      def create_title
        params[:title].presence || "Session #{Time.current.strftime('%Y-%m-%d %H:%M')}"
      end

      def extract_content
        if params[:session_file].respond_to?(:read)
          params[:session_file].read.force_encoding("UTF-8")
        elsif params[:body].present?
          params[:body].to_s.force_encoding("UTF-8")
        end
      end

      def parse_json_param(key)
        raw = params[key]
        raw = JSON.parse(raw, max_nesting: 50) if raw.is_a?(String)
        raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
        raw
      end

      def session_index_json(session)
        {
          id: session.id,
          slug: session.slug,
          title: session.title,
          tool_name: session.tool_name,
          total_messages: session.total_messages,
          published: session.published,
          created_at: session.created_at.iso8601,
          updated_at: session.updated_at.iso8601,
          url: URL.url(agent_session_path(session))
        }
      end

      def session_create_json(session)
        {
          id: session.id,
          slug: session.slug,
          title: session.title,
          tool_name: session.tool_name,
          total_messages: session.total_messages,
          published: session.published,
          created_at: session.created_at.iso8601,
          url: URL.url(agent_session_path(session))
        }
      end

      def session_show_json(session)
        {
          id: session.id,
          slug: session.slug,
          title: session.title,
          tool_name: session.tool_name,
          total_messages: session.total_messages,
          curated_count: session.curated_count,
          published: session.published,
          metadata: session.metadata,
          messages: session.messages,
          curated_selections: session.curated_selections,
          slices: session.slices,
          created_at: session.created_at.iso8601,
          updated_at: session.updated_at.iso8601,
          url: URL.url(agent_session_path(session))
        }
      end
    end
  end
end
