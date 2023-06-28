module Slack
  class WorkflowWebhookWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 10

    def perform(message)
      Slack::WorkflowWebhook.call(message)
    end
  end
end
