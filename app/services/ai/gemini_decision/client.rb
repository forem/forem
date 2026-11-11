module Ai
  module GeminiDecision
    ##
    # Client for Google's Gemini Decisions API (https://aistudio.google.com/docs/decisions-api).
    #
    # Gemini Decision 1 (`gemini-decision-1`) evaluates typed questions (Noul, Choice, Score)
    # over shared input in a single prefill forward pass and returns calibrated outcome
    # probabilities with zero output tokens.
    #
    # Accepts questions built with `Ai::TypeSafe::Questions` and returns an `Ai::TypeSafe::Result`
    # so every judgment function in Forem can run on either Gemini Decision 1 or TypeSafe Jev
    # without duplicating question definitions or threshold policies.
    #
    # Wire-format adaptations from Forem's structured System One representation:
    # - Structured Hash/Array `state` is serialized to a JSON string `input`, while multimodal
    #   content blocks (`text`, `image`, `audio`, `video`, `document`) pass through directly.
    # - Question keys outside `[A-Za-z0-9_-]{1,64}` (such as `"tag::javascript"` or `"tag::c#"`)
    #   are mapped to collision-free wire keys and restored on the returned `Result`.
    # - Structured Hash/Array question instructions, choice descriptions, and score levels are
    #   serialized to JSON strings, `nil` choice descriptions become `""`, and Noul `true`/`false`
    #   criteria map to `true_description`/`false_description`.
    class Client
      include HTTParty
      base_uri "https://generativelanguage.googleapis.com/v1beta"

      DEFAULT_MODEL = (ENV["GEMINI_DECISION_API_MODEL"].presence || "gemini-decision-1").freeze
      TIMEOUT_SECONDS = 10
      MAX_RETRIES = 3
      FAIL_FAST = { timeout: 5, max_retries: 0 }.freeze
      RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504, 529].freeze
      NETWORK_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Errno::ECONNRESET,
                        Errno::ECONNREFUSED].freeze

      CIRCUIT_FAILURE_THRESHOLD = 5
      CIRCUIT_WINDOW = 1.minute
      CIRCUIT_COOLDOWN = 2.minutes
      CIRCUIT_FAILURES_KEY = "ai:gemini_decision:circuit:failures".freeze
      CIRCUIT_OPEN_KEY = "ai:gemini_decision:circuit:open".freeze

      VALID_QUESTION_KEY = /\A[A-Za-z0-9_-]{1,64}\z/
      CONTENT_BLOCK_TYPES = %w[text image audio video document].freeze

      class Error < StandardError
        attr_reader :status_code

        def initialize(message, status_code: nil)
          super(message)
          @status_code = status_code
        end
      end

      # Raised without calling the API while the circuit breaker is open.
      class CircuitOpenError < Error; end

      class << self
        def circuit_open?
          Rails.cache.exist?(CIRCUIT_OPEN_KEY, local_cache: false)
        end

        # Counts an outage-type failure (timeout, connection error, 429 or 5xx) and opens the
        # circuit once there are enough of them in the window.
        def record_outage_failure
          failures = Rails.cache.increment(CIRCUIT_FAILURES_KEY, 1, expires_in: CIRCUIT_WINDOW)
          return unless failures.to_i >= CIRCUIT_FAILURE_THRESHOLD

          Rails.cache.write(CIRCUIT_OPEN_KEY, true, expires_in: CIRCUIT_COOLDOWN)
          Rails.cache.delete(CIRCUIT_FAILURES_KEY)
          Rails.logger.warn("Gemini Decision circuit breaker opened for #{CIRCUIT_COOLDOWN.inspect} after " \
                            "#{failures} failures")
        rescue StandardError => e
          Rails.logger.error("Gemini Decision circuit breaker failed to record a failure: #{e}")
        end
      end

      attr_reader :model, :last_response

      def initialize(api_key: Ai::Base::DEFAULT_KEY, model: DEFAULT_MODEL, wrapper: nil, affected_user: nil,
                     affected_content: nil, timeout: TIMEOUT_SECONDS, max_retries: MAX_RETRIES)
        raise ArgumentError, "Gemini API key cannot be nil" if api_key.blank? && !Rails.env.test?

        @api_key = api_key
        @model = model
        @wrapper = wrapper
        @affected_user = affected_user
        @affected_content = affected_content
        @timeout = timeout
        @max_retries = max_retries
      end

      ##
      # Evaluates the questions against the shared input state.
      #
      # @param state [String, Hash, Array] Structured application state (serialized as JSON text)
      #   or Gemini Interactions-compatible multimodal Content block(s).
      # @param questions [Hash{String,Symbol => Hash}] Question id => question built with
      #   Ai::TypeSafe::Questions.
      # @return [Ai::TypeSafe::Result]
      def evaluate(state:, questions:)
        raise ArgumentError, "At least one question is required" if questions.blank?
        if self.class.circuit_open?
          raise CircuitOpenError, "Gemini Decision circuit breaker is open; skipping the call"
        end

        wire_questions, wire_to_original = normalize_questions(questions)
        body = {
          model: @model,
          input: format_input(state),
          questions: wire_questions
        }.to_json
        attempt = 0

        begin
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @last_response = nil
          @last_response = self.class.post("/decisions", body: body, headers: headers, timeout: @timeout)
          result = handle_response(@last_response, wire_to_original)
          log_audit(body, retry_count: attempt, latency_ms: elapsed_ms(start_time))
          result
        rescue Ai::Base::ProhibitedContentError => e
          log_audit(body, retry_count: attempt, latency_ms: elapsed_ms(start_time), error_message: e.message)
          raise
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
          "x-goog-api-key" => @api_key.to_s,
          "Content-Type" => "application/json"
        }
      end

      def format_input(state)
        return state.empty? ? " " : state if state.is_a?(String)
        return state if content_block?(state) || content_block_list?(state)

        json = state.to_json
        json.empty? ? " " : json
      end

      def content_block_list?(value)
        value.is_a?(Array) && value.any? && value.all? { |item| content_block?(item) }
      end

      def content_block?(value)
        return false unless value.is_a?(Hash)

        block_type = (value[:type] || value["type"]).to_s
        return false unless CONTENT_BLOCK_TYPES.include?(block_type)

        if block_type == "text"
          value.key?(:text) || value.key?("text")
        else
          value.key?(:data) || value.key?("data") || value.key?(:uri) || value.key?("uri")
        end
      end

      def text_content_block?(value)
        value.is_a?(Hash) &&
          (value[:type] || value["type"]).to_s == "text" &&
          (value.key?(:text) || value.key?("text"))
      end

      def normalize_questions(questions)
        string_keyed = questions.transform_keys(&:to_s)
        used_keys = string_keyed.keys.grep(VALID_QUESTION_KEY).to_set
        wire_questions = {}
        wire_to_original = {}

        string_keyed.each do |original_key, question|
          wire_key = if original_key.match?(VALID_QUESTION_KEY) && !wire_to_original.key?(original_key)
                       original_key
                     else
                       allocate_wire_key(original_key, used_keys)
                     end
          used_keys.add(wire_key)
          wire_to_original[wire_key] = original_key
          wire_questions[wire_key] = normalize_question(question)
        end

        [wire_questions, wire_to_original]
      end

      def allocate_wire_key(original_key, used_keys)
        slug = original_key.gsub(/[^A-Za-z0-9_-]+/, "_").gsub(/\A_+|_+\z/, "")
        candidate = slug.first(64).presence || "q"
        return candidate unless used_keys.include?(candidate)

        digest = Digest::SHA256.hexdigest(original_key)[0, 8]
        prefix = slug.first(55).presence || "q"
        "#{prefix}_#{digest}"
      end

      def normalize_question(question)
        type = (question[:type] || question["type"]).to_s
        raw_instructions = question[:instructions] || question["instructions"]
        raw_criteria = question.key?(:criteria) ? question[:criteria] : question["criteria"]

        normalized = {
          "type" => type,
          "instructions" => format_instructions(raw_instructions)
        }

        case type
        when "noul"
          criteria = format_noul_criteria(raw_criteria)
          normalized["criteria"] = criteria if criteria.present?
        when "choice"
          normalized["criteria"] = format_choice_criteria(raw_criteria)
        when "score"
          normalized["criteria"] = format_score_criteria(raw_criteria)
        end

        normalized
      end

      def format_instructions(instructions)
        return instructions if instructions.is_a?(String)
        return instructions if text_content_block?(instructions)
        if instructions.is_a?(Array) && instructions.any? && instructions.all? { |item| text_content_block?(item) }
          return instructions
        end

        instructions.to_json
      end

      def format_noul_criteria(criteria)
        return unless criteria.is_a?(Hash) && criteria.any?

        string_criteria = criteria.stringify_keys
        true_desc = first_non_nil(string_criteria, "true_description", "true")
        false_desc = first_non_nil(string_criteria, "false_description", "false")

        mapped = {}
        mapped["true_description"] = stringify_value(true_desc) unless true_desc.nil?
        mapped["false_description"] = stringify_value(false_desc) unless false_desc.nil?
        mapped
      end

      def format_choice_criteria(criteria)
        return {} unless criteria.is_a?(Hash)

        criteria.to_h do |option_key, description|
          [option_key.to_s, description.nil? ? "" : stringify_value(description)]
        end
      end

      def format_score_criteria(criteria)
        Array(criteria).map { |level| stringify_value(level) }
      end

      def stringify_value(value)
        value.is_a?(String) ? value : value.to_json
      end

      def first_non_nil(hash, *keys)
        keys.each do |key|
          return hash[key] if hash.key?(key) && !hash[key].nil?
        end
        nil
      end

      def handle_response(response, wire_to_original)
        unless response.success?
          raise_api_error(response)
        end

        parsed = response.parsed_response
        unless parsed.is_a?(Hash) && parsed["answers"].is_a?(Hash)
          raise Error, 'Malformed Gemini Decision response: "answers" key not found.'
        end

        remapped_answers = parsed["answers"].transform_keys { |wire_key| wire_to_original.fetch(wire_key, wire_key) }
        Ai::TypeSafe::Result.new(
          parsed.merge(
            "model" => parsed["model"] || @model,
            "answers" => remapped_answers,
          ),
        )
      end

      def raise_api_error(response)
        body = response.parsed_response
        error_obj = body.is_a?(Hash) ? body["error"] : nil
        error_code = error_obj.is_a?(Hash) ? error_obj["code"] : nil
        message = extract_error_message(body, error_obj)

        if error_code == "prohibited_content"
          raise Ai::Base::ProhibitedContentError,
                "Gemini Decision blocked the input as prohibited_content: #{message || 'Prohibited content'}"
        end

        raise Error.new("Gemini Decision API Error: #{response.code} - #{message || 'Unknown API Error'}",
                        status_code: response.code)
      end

      def extract_error_message(body, error_obj)
        if error_obj.is_a?(Hash)
          error_obj["message"]
        elsif error_obj.is_a?(String)
          error_obj
        elsif body.is_a?(Hash)
          body["detail"]
        end
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
        usage = parsed&.dig("usage")
        input_tokens = usage&.dig("total_input_tokens")
        output_tokens = usage&.dig("total_output_tokens")
        total_tokens = usage&.dig("total_tokens") ||
          (input_tokens && output_tokens ? input_tokens + output_tokens : nil)

        AiAudit.create!(
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
          total_token_count: total_tokens,
          latency_ms: latency_ms,
          status_code: @last_response&.code,
          error_message: error_message,
        )
      rescue StandardError => e
        Rails.logger.error("Failed to log Gemini Decision AiAudit: #{e}")
      end

      def wrapper_version
        return unless @wrapper&.class&.const_defined?(:VERSION, false)

        @wrapper.class.const_get(:VERSION, false)
      end
    end
  end
end
