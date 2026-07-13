require "rails_helper"

RSpec.describe Emails::ReengagementPruneWorker do
  def dormant_user
    u = create(:user)
    u.notification_setting.update!(email_digest_periodic: true, email_newsletter: true)
    u.update_columns(User::ACTIVITY_TIMESTAMP_KEYS.index_with { 3.years.ago })
    u
  end

  it "unsubscribes a silent, still-inactive user" do
    user = dormant_user
    described_class.new.perform([user.id])
    setting = user.notification_setting.reload
    expect(setting.email_digest_periodic).to be(false)
    expect(setting.email_newsletter).to be(false)
    expect(setting.email_reengagement_pruned_at).to be_present
  end

  it "spares a user who confirmed" do
    user = dormant_user
    user.notification_setting.update!(email_reengagement_confirmed_at: 1.day.ago)
    described_class.new.perform([user.id])
    setting = user.notification_setting.reload
    expect(setting.email_digest_periodic).to be(true)
    expect(setting.email_reengagement_pruned_at).to be_nil
  end

  it "spares a user who re-engaged since the ask" do
    user = dormant_user
    user.update_columns(last_sign_in_at: 2.days.ago)
    described_class.new.perform([user.id])
    setting = user.notification_setting.reload
    expect(setting.email_digest_periodic).to be(true)
    expect(setting.email_reengagement_pruned_at).to be_nil
  end

  it "does not re-prune an already-pruned user" do
    user = dormant_user
    original = 2.weeks.ago.change(usec: 0)
    user.notification_setting.update!(email_reengagement_pruned_at: original)
    described_class.new.perform([user.id])
    expect(user.notification_setting.reload.email_reengagement_pruned_at).to eq(original)
  end

  it "does not raise and continues the batch when a user has no notification_setting" do
    nil_setting_user = dormant_user
    nil_setting_user.notification_setting.destroy!
    nil_setting_user.reload

    normal_user = dormant_user

    expect do
      described_class.new.perform([nil_setting_user.id, normal_user.id])
    end.not_to raise_error

    setting = normal_user.notification_setting.reload
    expect(setting.email_reengagement_pruned_at).to be_present
    expect(setting.email_digest_periodic).to be(false)
  end
end
