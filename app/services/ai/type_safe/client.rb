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
    #
    # Outages: callers on latency-sensitive queues (the high-priority spam and moderation jobs)
    # pass FAIL_FAST so one call can hold a worker for at most one short attempt. A circuit
    # breaker shared across processes (via Rails.cache) also stops calling TypeSafe for
    # CIRCUIT_COOLDOWN after CIRCUIT_FAILURE_THRESHOLD outage failures within CIRCUIT_WINDOW,
    # raising CircuitOpenError immediately instead. Every caller fails open on errors.
    class Client
      include HTTParty
      base_uri "https://api.typesafe.ai/v1"

      DEFAULT_KEY = ENV["TYPESAFE_API_KEY"].presence.freeze
      # "jev-latest" moves when TypeSafe ships a new release. Pin a versioned ID
      # (e.g. "jev-1.13.0") via TYPESAFE_API_MODEL once thresholds are tuned against it.
      # `presence` so a blank value from a copied .env file does not become the model name.
      DEFAULT_MODEL = (ENV["TYPESAFE_API_MODEL"].presence || "jev-latest").freeze
      # Matches the TypeSafe SDKs' default per-request timeout.
      TIMEOUT_SECONDS = 10
      MAX_RETRIES = 3
      # For calls inside high-priority jobs: one short attempt and no retries, the same as the
      # Gemini calls on those paths. A missed answer only means the caller falls back.
      FAIL_FAST = { timeout: 5, max_retries: 0 }.freeze
      # 429: rate limited, 529: overloaded. Both are documented as retryable with backoff.
      RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504, 529].freeze
      NETWORK_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Errno::ECONNRESET,
                        Errno::ECONNREFUSED].freeze

      CIRCUIT_FAILURE_THRESHOLD = 5
      CIRCUIT_WINDOW = 1.minute
      CIRCUIT_COOLDOWN = 2.minutes
      CIRCUIT_FAILURES_KEY = "ai:type_safe:circuit:failures".freeze
      CIRCUIT_OPEN_KEY = "ai:type_safe:circuit:open".freeze

      class Error < StandardError
        attr_reader :status_code

        def initialize(message, status_code: nil)
          super(message)
          @status_code = status_code
        end
      end

      # Raised without calling TypeSafe while the circuit breaker is open.
      class CircuitOpenError < Error; end

      class << self
        def circuit_open?
          Rails.cache.exist?(CIRCUIT_OPEN_KEY)
        end

        # Counts an outage-type failure (timeout, connection error, 429 or 5xx) and opens the
        # circuit once there are enough of them in the window.
        def record_outage_failure
          failures = Rails.cache.increment(CIRCUIT_FAILURES_KEY, 1, expires_in: CIRCUIT_WINDOW)
          return unless failures.to_i >= CIRCUIT_FAILURE_THRESHOLD

          Rails.cache.write(CIRCUIT_OPEN_KEY, true, expires_in: CIRCUIT_COOLDOWN)
          Rails.cache.delete(CIRCUIT_FAILURES_KEY)
          Rails.logger.warn("TypeSafe circuit breaker opened for #{CIRCUIT_COOLDOWN.inspect} after " \
                            "#{failures} failures")
        rescue StandardError => e
          Rails.logger.error("TypeSafe circuit breaker failed to record a failure: #{e}")
        end
      end

      attr_reader :model, :last_response

      def initialize(api_key: DEFAULT_KEY, model: DEFAULT_MODEL, wrapper: nil, affected_user: nil,
                     affected_content: nil, timeout: TIMEOUT_SECONDS, max_retries: MAX_RETRIES)
        raise ArgumentError, "TypeSafe API key cannot be nil" if api_key.blank? && !Rails.env.test?

        @api_key = api_key
        @model = model
        @wrapper = wrapper
        @affected_user = affected_user
        @affected_content = affected_content
        @timeout = timeout
        @max_retries = max_retries
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
        raise CircuitOpenError, "TypeSafe circuit breaker is open; skipping the call" if self.class.circuit_open?

        body = { model: @model, state: state, questions: questions.transform_keys(&:to_s) }.to_json
        attempt = 0

        begin
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @last_response = nil
          @last_response = self.class.post("/systemone", body: body, headers: headers, timeout: @timeout)
          result = handle_response(@last_response)
          log_audit(body, retry_count: attempt, latency_ms: elapsed_ms(start_time))
          result
        rescue Error, *NETWORK_ERRORS => e
          log_audit(body, retry_count: attempt, latency_ms: elapsed_ms(start_time), error_message: e.message)

          raise unless retryable?(e)

          self.class.record_outage_failure
          raise if attempt >= @max_retries || self.class.circuit_open?

          attempt += 1
          sleep(backoff_seconds(attempt)) unless Rails.env.test?
          retry
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
