module Slack
  module WorkflowWebhook
    def self.call(message)
      return if ApplicationConfig["SLACK_WORKFLOW_WEBHOOK_URL"].blank?
      return if message.blank?

      HTTParty.post(
        ApplicationConfig["SLACK_WORKFLOW_WEBHOOK_URL"],
        body: { message: message }.to_json,
        headers: { "Content-Type" => "application/json" },
      )
    end
  end
end
