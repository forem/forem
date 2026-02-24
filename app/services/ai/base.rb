module Ai
  # A base class for interacting with the Google Gemini API using HTTParty.
  class Base
    include HTTParty
    base_uri "https://generativelanguage.googleapis.com/v1beta"
    DEFAULT_MODEL = ENV.fetch("GEMINI_API_MODEL", "gemini-2.5-pro").freeze
    DEFAULT_KEY = ENV["GEMINI_API_KEY"].freeze
    attr_reader :model, :last_response

    def initialize(api_key: DEFAULT_KEY, model: DEFAULT_MODEL, wrapper: nil, affected_user: nil, affected_content: nil)
      raise ArgumentError, "API key cannot be nil" if api_key.nil? && !Rails.env.test?

      @api_key = api_key
      @model = model
      @wrapper = wrapper
      @affected_user = affected_user
      @affected_content = affected_content
      @options = {
        headers: {
          "Content-Type" => "application/json"
        }
      }
    end

    def call(prompt, retry_count: 0)
      api_url = "/models/#{@model}:generateContent?key=#{@api_key}"
      body = {
        contents: [{
          parts: [{
            text: prompt
          }]
        }]
      }

      @options[:body] = body.to_json

      start_time = Time.now.to_f
      begin
        @last_response = self.class.post(api_url, @options)

        # handle_response will raise if the response is not success? or is malformed
        result = handle_response(@last_response)

        latency_ms = ((Time.now.to_f - start_time) * 1000).to_i
        status_code = @last_response.code

        log_audit(retry_count: retry_count, latency_ms: latency_ms, status_code: status_code)

        result
      rescue StandardError => e
        latency_ms = ((Time.now.to_f - start_time) * 1000).to_i
        status_code = @last_response&.code
        log_audit(retry_count: retry_count, latency_ms: latency_ms, status_code: status_code, error_message: e.message)
        raise e
      end
    end

    private

    def log_audit(retry_count: 0, latency_ms: nil, status_code: nil, error_message: nil)
      prompt_tokens = @last_response&.parsed_response&.dig("usageMetadata", "promptTokenCount")
      candidates_tokens = @last_response&.parsed_response&.dig("usageMetadata", "candidatesTokenCount")
      total_tokens = @last_response&.parsed_response&.dig("usageMetadata", "totalTokenCount")

      AiAudit.create!(
        ai_model: @model,
        wrapper_object_class: @wrapper&.class&.name,
        wrapper_object_version: @wrapper&.class&.const_defined?(:VERSION) ? @wrapper.class::VERSION : nil,
        request_body: @options[:body],
        response_body: @last_response&.parsed_response,
        retry_count: retry_count,
        affected_user: @affected_user,
        affected_content: @affected_content,
        prompt_token_count: prompt_tokens,
        candidates_token_count: candidates_tokens,
        total_token_count: total_tokens,
        latency_ms: latency_ms,
        status_code: status_code,
        error_message: error_message,
      )
    rescue StandardError => e
      raise e if Rails.env.test?

      Rails.logger.error("Failed to log AiAudit: #{e}")
    end

    def handle_response(response)
      unless response.success?
        error_info = response.parsed_response["error"] || { "message" => "Unknown API Error" }
        raise "API Error: #{response.code} - #{error_info['message']}"
      end

      parsed_response = response.parsed_response
      raise 'Malformed response: "candidates" key not found.' unless parsed_response.key?("candidates")

      candidate = parsed_response["candidates"].first
      raise "No candidates received from the API." unless candidate

      candidate.dig("content", "parts", 0, "text")
    end
  end
end
