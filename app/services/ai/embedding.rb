module Ai
  class Embedding < Base
    DEFAULT_EMBEDDING_MODEL = ENV.fetch("GEMINI_EMBEDDING_MODEL", "gemini-embedding-2").freeze


    def initialize(api_key: DEFAULT_KEY, model: DEFAULT_EMBEDDING_MODEL, wrapper: nil, affected_user: nil, affected_content: nil)
      super
    end

    def call(text, task_type: "RETRIEVAL_DOCUMENT", output_dimensionality: 768)
      api_url = "/models/#{@model}:embedContent?key=#{@api_key}"
      body = {
        model: "models/#{@model}",
        content: {
          parts: [{
            text: text
          }]
        },
        outputDimensionality: output_dimensionality,
        taskType: task_type
      }

      @options[:body] = body.to_json

      start_time = Time.now.to_f
      begin
        @last_response = self.class.post(api_url, @options)
        
        unless @last_response.success?
          error_info = @last_response.parsed_response["error"] || { "message" => "Unknown API Error" }
          raise "API Error: #{@last_response.code} - #{error_info['message']}"
        end

        parsed_response = @last_response.parsed_response
        embedding_values = parsed_response.dig("embedding", "values")
        
        raise 'Malformed response: "embedding" key not found.' unless embedding_values

        log_audit(latency_ms: ((Time.now.to_f - start_time) * 1000).to_i, status_code: @last_response.code)

        embedding_values
      rescue StandardError => e
        log_audit(latency_ms: ((Time.now.to_f - start_time) * 1000).to_i, status_code: @last_response&.code, error_message: e.message)
        raise e
      end
    end
  end
end
