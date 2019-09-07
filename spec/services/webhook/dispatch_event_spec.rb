require "rails_helper"

RSpec.describe Webhook::DispatchEvent, type: :service do
  let!(:article) { create(:article) }

  it "does nothing if there are no corresponding endpoints" do
    create(:webhook_endpoint, events: %w[article_created])
    expect do
      described_class.call("article_destroyed", article)
    end.not_to have_enqueued_job(Webhook::DispatchEventJob)
  end

  it "schedules jobs" do
    create(:webhook_endpoint, events: %w[article_created], target_url: "https://create-webhooks.example.com/accept")
    create(:webhook_endpoint, events: %w[article_created article_updated article_destroyed], target_url: "https://all-webhooks.example.com/accept")
    create(:webhook_endpoint, events: %w[article_destroyed], target_url: "https://destroy-webhooks.example.com/accept")
    expect do
      described_class.call("article_created", article)
    end.to have_enqueued_job(Webhook::DispatchEventJob).twice
  end
end
