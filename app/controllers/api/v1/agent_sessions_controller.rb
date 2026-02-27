module Api
  module V1
    class AgentSessionsController < ApiController
      before_action :authenticate_with_api_key!
      before_action :set_agent_session, only: [:show]

      def index
        @agent_sessions = @user.agent_sessions.order(updated_at: :desc)
        render json: @agent_sessions.map { |s| session_index_json(s) }
      end

      def show
        render json: session_show_json(@agent_session)
      end

      def create
        @agent_session = @user.agent_sessions.new(title: create_title)

        content = extract_content
        unless content
          render json: { error: "Missing session content. Provide 'body' or 'session_file'.",
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

        if @agent_session.save
          render json: session_create_json(@agent_session), status: :created
        else
          render json: { error: @agent_session.errors.full_messages.join(", "), status: 422 },
                 status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error("Agent session API parse error: #{e.class}: #{e.message}")
        render json: { error: "Failed to parse session content. Please check the format and try again.", status: 422 },
               status: :unprocessable_entity
      end

      private

      def set_agent_session
        @agent_session = @user.agent_sessions.find_by!(slug: params[:id])
      rescue ActiveRecord::RecordNotFound
        @agent_session = @user.agent_sessions.find(params[:id])
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
