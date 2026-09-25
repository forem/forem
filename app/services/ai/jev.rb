module Ai
  # A client for TypeSafe's Jev model. Jev doesn't generate text: it answers typed questions
  # (noul/choice/score) about a piece of state with probabilities.
  #
  # @see https://docs.typesafe.ai/api
  class Jev
    include HTTParty
    base_uri "https://api.typesafe.ai/v1"
    default_timeout 10
    DEFAULT_KEY = ENV["TYPESAFE_API_KEY"].freeze
    MODEL = "jev-latest".freeze

    def initialize(api_key: DEFAULT_KEY, wrapper: nil, affected_user: nil, affected_content: nil)
      raise ArgumentError, "API key cannot be nil" if api_key.nil? && !Rails.env.test?

      @api_key = api_key
      @wrapper = wrapper
      @affected_user = affected_user
      @affected_content = affected_content
    end

    # @param state [String, Hash] what the questions are about
    # @param questions [Hash] question id => { type:, instructions:, criteria: }
    # @return [Hash] the answers, keyed by question id
    def call(state:, questions:)
      @body = { model: MODEL, state: state, questions: questions }.to_json
      start_time = Time.now.to_f
      @response = self.class.post("/systemone", body: @body, headers: {
                                    "Authorization" => "Bearer #{@api_key}",
                                    "Content-Type" => "application/json"
                                  })
      raise "Jev API Error: #{@response.code}" unless @response.success?

      answers = @response.parsed_response.fetch("answers")
      log_audit(start_time)
      answers
    rescue StandardError => e
      log_audit(start_time, error_message: e.message)
      raise e
    end

    private

    def log_audit(start_time, error_message: nil)
      parsed = @response&.parsed_response
      input_tokens = parsed&.dig("usage", "input_tokens")

      AiAudit.create!(
        ai_model: parsed&.dig("model") || MODEL,
        wrapper_object_class: @wrapper&.class&.name,
        wrapper_object_version: @wrapper && @wrapper.class::VERSION,
        request_body: @body,
        response_body: parsed,
        affected_user: @affected_user,
        affected_content: @affected_content,
        prompt_token_count: input_tokens,
        total_token_count: input_tokens,
        latency_ms: ((Time.now.to_f - start_time) * 1000).to_i,
        status_code: @response&.code,
        error_message: error_message,
      )
    rescue StandardError => e
      Rails.logger.error("Failed to log AiAudit: #{e}")
    end
  end
end
