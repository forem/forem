# spec/models/email_reengagement_recipient_spec.rb
require "rails_helper"

RSpec.describe EmailReengagementRecipient do
  let(:user) { create(:user) }

  it "enforces one row per user per campaign" do
    described_class.create!(user: user, campaign_key: "c1")
    dup = described_class.new(user: user, campaign_key: "c1")
    expect(dup).not_to be_valid
  end

  it "filters unconfirmed, not-pruned, sent recipients for a campaign" do
    confirmed = described_class.create!(user: create(:user), campaign_key: "c1", sent_at: Time.current, confirmed_at: Time.current)
    silent    = described_class.create!(user: create(:user), campaign_key: "c1", sent_at: Time.current)
    pruned    = described_class.create!(user: create(:user), campaign_key: "c1", sent_at: Time.current, pruned_at: Time.current)
    _other    = described_class.create!(user: create(:user), campaign_key: "c2", sent_at: Time.current)

    scope = described_class.for_campaign("c1").sent.unconfirmed.not_pruned
    expect(scope).to contain_exactly(silent)
    expect(scope).not_to include(confirmed, pruned)
  end
end
