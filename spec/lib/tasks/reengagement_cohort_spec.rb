require "rails_helper"

RSpec.describe Reengagement do
  let(:dormant) { create(:user) }

  before do
    two_years = 3.years.ago
    dormant.update_columns(
      last_sign_in_at: two_years, last_comment_at: two_years,
      last_reacted_at: two_years, last_article_at: two_years, last_presence_at: two_years
    )
    Ahoy::Message.create!(user_id: dormant.id, to: dormant.email, sent_at: 1.day.ago, mailer: "DigestMailer")
  end

  it "adds an eligible dormant emailed user" do
    expect { described_class.build_cohort(campaign_key: "c1") }
      .to change { EmailReengagementRecipient.for_campaign("c1").count }.by(1)
  end

  it "excludes an active user" do
    active = create(:user)
    active.update_columns(last_sign_in_at: 1.day.ago)
    Ahoy::Message.create!(user_id: active.id, to: active.email, sent_at: 1.day.ago, mailer: "DigestMailer")
    described_class.build_cohort(campaign_key: "c1")
    expect(EmailReengagementRecipient.exists?(user_id: active.id, campaign_key: "c1")).to be(false)
  end

  it "excludes a suspended user" do
    dormant.add_role(:suspended)
    described_class.build_cohort(campaign_key: "c1")
    expect(EmailReengagementRecipient.exists?(user_id: dormant.id, campaign_key: "c1")).to be(false)
  end

  it "is idempotent" do
    described_class.build_cohort(campaign_key: "c1")
    expect { described_class.build_cohort(campaign_key: "c1") }
      .not_to change { EmailReengagementRecipient.for_campaign("c1").count }
  end
end
