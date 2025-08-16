module Ai
  # A base class for interacting with the Google Gemini API using HTTParty.
  class Base
    include HTTParty
    base_uri "https://generativelanguage.googleapis.com/v1beta"
    DEFAULT_MODEL = ENV.fetch("GEMINI_API_MODEL", "gemini-2.5-pro").freeze
    DEFAULT_KEY = ENV["GEMINI_API_KEY"].freeze
    attr_reader :model, :last_response

    def initialize(api_key: DEFAULT_KEY, model: DEFAULT_MODEL)
      raise ArgumentError, "API key cannot be nil" if api_key.nil? && !Rails.env.test?

      @api_key = api_key
      @model = model
      @options = {
        headers: {
          "Content-Type" => "application/json"
        }
      }
    end

    def call(prompt)
      api_url = "/models/#{@model}:generateContent?key=#{@api_key}"
      body = {
        contents: [{
          parts: [{
            text: prompt
          }]
        }]
      }

      @options[:body] = body.to_json
      @last_response = self.class.post(api_url, @options)

      handle_response(@last_response)
    end

    private

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
