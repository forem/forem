module Ai
  module TypeSafe
    ##
    # Client for TypeSafe's System One evaluation endpoint (https://docs.typesafe.ai/api).
    #
    # System One models such as Jev do not generate text. A request evaluates one `state`
    # against a map of typed questions (Noul, Choice, Score) and returns one typed answer
    # per question. All questions in a request run in parallel over the same state, so
    # callers should batch every question they might need into a single #evaluate call.
    #
    # Every call is recorded as an AiAudit row, mirroring Ai::Base.
    class Client
      include HTTParty
      base_uri "https://api.typesafe.ai/v1"

      DEFAULT_KEY = ENV["TYPESAFE_API_KEY"].presence.freeze
      # "jev-latest" moves when TypeSafe ships a new release. Pin a versioned ID
      # (e.g. "jev-1.13.0") via TYPESAFE_API_MODEL once thresholds are tuned against it.
      # `presence` so a blank value from a copied .env file does not become the model name.
      DEFAULT_MODEL = (ENV["TYPESAFE_API_MODEL"].presence || "jev-latest").freeze
      TIMEOUT_SECONDS = 20
      MAX_RETRIES = 3
      # 429: rate limited, 529: overloaded. Both are documented as retryable with backoff.
      RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504, 529].freeze

      class Error < StandardError
        attr_reader :status_code

        def initialize(message, status_code: nil)
          super(message)
          @status_code = status_code
        end
      end

      attr_reader :model, :last_response

      def initialize(api_key: DEFAULT_KEY, model: DEFAULT_MODEL, wrapper: nil, affected_user: nil,
                     affected_content: nil)
        raise ArgumentError, "TypeSafe API key cannot be nil" if api_key.blank? && !Rails.env.test?

        @api_key = api_key
        @model = model
        @wrapper = wrapper
        @affected_user = affected_user
        @affected_content = affected_content
      end

      ##
      # Evaluates the questions against the state.
      #
      # @param state [String, Hash, Array] The content to judge. Prefer a Hash with named
      #   fields so questions can reference parts of it with backticked paths.
      # @param questions [Hash{String,Symbol => Hash}] Question id => question built with
      #   Ai::TypeSafe::Questions. Ids are for code only and are never sent to the model.
      # @return [Ai::TypeSafe::Result]
      def evaluate(state:, questions:)
        raise ArgumentError, "At least one question is required" if questions.blank?

        body = { model: @model, state: state, questions: questions.transform_keys(&:to_s) }.to_json
        attempt = 0

        begin
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @last_response = nil
          @last_response = self.class.post("/systemone", body: body, headers: headers, timeout: TIMEOUT_SECONDS)
          result = handle_response(@last_response)
          log_audit(body, retry_count: attempt, latency_ms: elapsed_ms(start_time))
          result
        rescue Error, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET => e
          log_audit(body, retry_count: attempt, latency_ms: elapsed_ms(start_time), error_message: e.message)

          if retryable?(e) && attempt < MAX_RETRIES
            attempt += 1
            sleep(backoff_seconds(attempt)) unless Rails.env.test?
            retry
          end

          raise
        end
      end

      private

      def headers
        {
          "Authorization" => "Bearer #{@api_key}",
          "Content-Type" => "application/json"
        }
      end

      def handle_response(response)
        unless response.success?
          body = response.parsed_response
          message = body.is_a?(Hash) ? body["detail"] || body["error"] : nil
          raise Error.new("TypeSafe API Error: #{response.code} - #{message || 'Unknown API Error'}",
                          status_code: response.code)
        end

        parsed = response.parsed_response
        unless parsed.is_a?(Hash) && parsed["answers"].is_a?(Hash)
          raise Error, 'Malformed TypeSafe response: "answers" key not found.'
        end

        Result.new(parsed)
      end

      def retryable?(error)
        return true unless error.is_a?(Error)

        RETRYABLE_STATUS_CODES.include?(error.status_code)
      end

      # Honors retry-after when present, otherwise exponential backoff: 1s, 2s, 4s.
      def backoff_seconds(attempt)
        retry_after = @last_response&.headers&.[]("retry-after").to_f
        return retry_after.clamp(0, 30) if retry_after.positive?

        2**(attempt - 1)
      end

      def elapsed_ms(start_time)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).to_i
      end

      def log_audit(body, retry_count: 0, latency_ms: nil, error_message: nil)
        parsed = @last_response&.parsed_response
        parsed = nil unless parsed.is_a?(Hash)
        input_tokens = parsed&.dig("usage", "input_tokens")
        output_tokens = parsed&.dig("usage", "output_tokens")

        AiAudit.create!(
          # The response reports the versioned model that answered (e.g. jev-1.13.0), which is
          # what matters when comparing results across alias moves.
          ai_model: parsed&.dig("model") || @model,
          wrapper_object_class: @wrapper&.class&.name,
          wrapper_object_version: wrapper_version,
          request_body: JSON.parse(body),
          response_body: parsed,
          retry_count: retry_count,
          affected_user: @affected_user,
          affected_content: @affected_content,
          prompt_token_count: input_tokens,
          candidates_token_count: output_tokens,
          total_token_count: input_tokens && output_tokens ? input_tokens + output_tokens : nil,
          latency_ms: latency_ms,
          status_code: @last_response&.code,
          error_message: error_message,
        )
      rescue StandardError => e
        Rails.logger.error("Failed to log TypeSafe AiAudit: #{e}")
      end

      def wrapper_version
        return unless @wrapper&.class&.const_defined?(:VERSION, false)

        @wrapper.class.const_get(:VERSION, false)
      end
    end
  end
end
