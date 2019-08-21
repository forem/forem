require "rails_helper"

RSpec.describe Webhook::Endpoint, type: :model do
  let(:user) { create(:user) }
  let!(:endpoint) { create(:webhook_endpoint, user: user) }
  let!(:epoint) { create(:webhook_endpoint, events: %w[article_created]) }
  let!(:epoint2) { create(:webhook_endpoint, events: %w[article_destroyed], user: user) }
  let!(:epoint3) { create(:webhook_endpoint, events: %w[article_updated article_destroyed]) }

  it "is valid" do
    expect(endpoint).to be_valid
  end

  it "finds for events" do
    d_points = described_class.for_events("article_destroyed")
    expect(d_points.pluck(:id).sort).to eq([endpoint, epoint2, epoint3].map(&:id).sort)
  end

  it "finds for_events array" do
    d_points = described_class.for_events("article_created")
    expect(d_points.pluck(:id).sort).to eq([endpoint, epoint].map(&:id).sort)
  end

  it "belongs to user" do
    expect(user.webhook_endpoints.pluck(:id).sort).to eq([endpoint, epoint2].map(&:id).sort)
  end

  it "sets events according to the list" do
    webhook = create(:webhook_endpoint, events: %w[article_updated other_updated cool article_created])
    webhook.reload
    expect(webhook.events.sort).to eq(%w[article_created article_updated])
  end
end
