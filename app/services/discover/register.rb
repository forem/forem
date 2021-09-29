module Discover
  class Register
    FOREM_DISCOVER_URL = "https://discover.forem.com/api/forems/register".freeze

    def initialize(domain:)
      @domain = domain
    end

    def self.call(**args)
      new(**args).call
    end

    def call
      return unless @domain

      response = HTTParty.post(FOREM_DISCOVER_URL, body: { domain: @domain })

      unless response.success?
        error_message = %(
          "Discover::Register Error - Forem Discover registration error.
          #{response.message}.
          #{response.body}."
        )
        Rails.logger.error error_message

        # raising an error to trigger the Sidekiq Worker to retry
        raise StandardError, "Discover::Register Error"
      end

      Rails.logger.info JSON.parse(response.parsed_response)["message"]
      true
    end
  end
end
