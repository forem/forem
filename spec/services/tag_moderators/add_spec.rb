require "rails_helper"

RSpec.describe TagModerators::Add, type: :service do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }

  it "adds tag moderator role" do
    described_class.call(user.id, tag.id)
    expect(user.tag_moderator?(tag: tag)).to be true
  end

  it "updates user's email_tag_mod_newsletter" do
    described_class.call(user.id, tag.id)
    expect(user.reload.notification_setting.email_tag_mod_newsletter?).to be true
  end

  it "calls Moderators::AddTrustedRole" do
    allow(TagModerators::AddTrustedRole).to receive(:call)
    described_class.call(user.id, tag.id)
    expect(TagModerators::AddTrustedRole).to have_received(:call).with(user)
  end

  it "autosupports tag" do
    unsupported_tag = create(:tag, supported: false)
    described_class.call(user.id, unsupported_tag.id)
    expect(unsupported_tag.reload.supported?).to be true
  end

  it "returns success when needed" do
    result = described_class.call(user.id, tag.id)
    expect(result.success?).to be true
  end

  it "returns error when notification setting is not updated" do
    setting = instance_double(Users::NotificationSetting, update: false, errors_as_sentence: "invalid values")
    double_user = instance_double(User, notification_setting: setting, id: -1)
    allow(User).to receive(:find).with(double_user.id).and_return(double_user)
    result = described_class.call(double_user.id, tag.id)
    expect(result.success?).to be false
    expect(result.errors).to eq("invalid values")
  end
end
