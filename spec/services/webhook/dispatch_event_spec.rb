require "rails_helper"

RSpec.describe Webhook::DispatchEvent, type: :service do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }

  it "does nothing if there are no corresponding endpoints" do
    create(:webhook_endpoint, events: %w[article_created], user: user)
    sidekiq_assert_no_enqueued_jobs(only: Webhook::DispatchEventWorker) do
      described_class.call("article_destroyed", article)
    end
  end

  it "schedules jobs" do
    create(:webhook_endpoint, events: %w[article_created], user: user, target_url: "https://create-webhooks.example.com/accept")
    create(:webhook_endpoint, events: %w[article_created article_updated article_destroyed], user: user, target_url: "https://all-webhooks.example.com/accept")
    create(:webhook_endpoint, events: %w[article_destroyed], user: user, target_url: "https://destroy-webhooks.example.com/accept")
    sidekiq_assert_enqueued_jobs(2, only: Webhook::DispatchEventWorker) do
      described_class.call("article_created", article)
    end
  end

  it "doesn't schedule jobs if the endpoints belong to another user" do
    user2 = create(:user)
    create(:webhook_endpoint, events: %w[article_created], user: user2, target_url: "https://create-webhooks.example.com/accept")
    sidekiq_assert_no_enqueued_jobs(only: Webhook::DispatchEventWorker) do
      described_class.call("article_created", article)
    end
  end
end
