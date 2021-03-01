require "rails_helper"

RSpec.describe Webhook::Endpoint, type: :model do
  let!(:endpoint) do
    create(
      :webhook_endpoint, user: user, events: %w[article_created article_updated article_destroyed]
    )
  end
  let(:user) { create(:user) }

  describe "validations" do
    it { is_expected.to belong_to(:user).inverse_of(:webhook_endpoints) }
    it { is_expected.to belong_to(:oauth_application).inverse_of(:webhook_endpoints).optional }

    it { is_expected.to validate_presence_of(:events) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:target_url) }
    it { is_expected.to validate_presence_of(:user_id) }

    it { is_expected.to validate_uniqueness_of(:target_url) }

    it { is_expected.to allow_value("https://foo.com").for(:target_url) }
    it { is_expected.not_to allow_value("http://foo.com").for(:target_url) }
  end

  it "is valid" do
    expect(endpoint).to be_valid
  end

  it "sets events according to the list" do
    webhook = create(
      :webhook_endpoint, events: %w[article_updated other_updated cool article_created]
    )
    webhook.reload
    expect(webhook.events.sort).to eq(%w[article_created article_updated])
  end

  context "when endpoints exist" do
    let!(:epoint2) { create(:webhook_endpoint, events: %w[article_destroyed], user: user) }
    let!(:epoint3) { create(:webhook_endpoint, events: %w[article_updated article_destroyed]) }

    before do
      create(:webhook_endpoint, events: %w[article_created])
    end

    it "finds for events" do
      d_points = described_class.for_events("article_destroyed")
      expect(d_points.ids.sort).to eq([endpoint, epoint2, epoint3].map(&:id).sort)
    end

    it "finds for_events array" do
      endpoints = described_class.for_events(%w[article_created article_destroyed])
      expect(endpoints.ids).to eq([endpoint.id])
    end

    it "belongs to user" do
      expect(user.webhook_endpoints.ids.sort).to eq([endpoint, epoint2].map(&:id).sort)
    end
  end
end
