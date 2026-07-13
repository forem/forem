require "rails_helper"

RSpec.describe Emails::ReengagementPruneWorker do
  def dormant_user
    u = create(:user)
    u.notification_setting.update!(email_digest_periodic: true, email_newsletter: true)
    u.update_columns(last_sign_in_at: 3.years.ago, last_presence_at: 3.years.ago,
                     last_comment_at: 3.years.ago, last_reacted_at: 3.years.ago, last_article_at: 3.years.ago)
    u
  end

  it "unsubscribes a silent, still-inactive recipient" do
    user = dormant_user
    rec = EmailReengagementRecipient.create!(user: user, campaign_key: "c1", sent_at: 30.days.ago)
    described_class.new.perform("c1", [user.id])
    expect(user.notification_setting.reload.email_digest_periodic).to be(false)
    expect(user.notification_setting.reload.email_newsletter).to be(false)
    expect(rec.reload.pruned_at).to be_present
  end

  it "spares a recipient who confirmed" do
    user = dormant_user
    rec = EmailReengagementRecipient.create!(user: user, campaign_key: "c1", sent_at: 30.days.ago,
                                             confirmed_at: 1.day.ago)
    described_class.new.perform("c1", [user.id])
    expect(user.notification_setting.reload.email_digest_periodic).to be(true)
    expect(rec.reload.pruned_at).to be_nil
  end

  it "spares a recipient who re-engaged since send" do
    user = dormant_user
    user.update_columns(last_sign_in_at: 2.days.ago)
    rec = EmailReengagementRecipient.create!(user: user, campaign_key: "c1", sent_at: 30.days.ago)
    described_class.new.perform("c1", [user.id])
    expect(user.notification_setting.reload.email_digest_periodic).to be(true)
    expect(rec.reload.pruned_at).to be_nil
  end

  it "does not raise and continues the batch when a recipient has no notification_setting" do
    nil_setting_user = dormant_user
    nil_setting_user.notification_setting.destroy!
    nil_setting_user.reload
    nil_setting_rec = EmailReengagementRecipient.create!(
      user: nil_setting_user, campaign_key: "c1", sent_at: 30.days.ago,
    )

    normal_user = dormant_user
    normal_rec = EmailReengagementRecipient.create!(user: normal_user, campaign_key: "c1", sent_at: 30.days.ago)

    expect do
      described_class.new.perform("c1", [nil_setting_user.id, normal_user.id])
    end.not_to raise_error

    expect(nil_setting_rec.reload.pruned_at).to be_nil
    expect(normal_rec.reload.pruned_at).to be_present
    expect(normal_user.notification_setting.reload.email_digest_periodic).to be(false)
  end
end
