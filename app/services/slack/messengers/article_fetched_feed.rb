module Slack
  module Messengers
    module ArticleFetchedFeed
      def self.call(message)
        return if ApplicationConfig["SLACK_WORKFLOW_WEBHOOK_URL"].blank?

        HTTParty.post(
          ApplicationConfig["SLACK_WORKFLOW_WEBHOOK_URL"],
          body: { message: message }.to_json,
          headers: { "Content-Type" => "application/json" },
        )
      end
    end
  end
end
