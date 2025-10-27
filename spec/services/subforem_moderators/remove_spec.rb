require "rails_helper"

RSpec.describe SubforemModerators::Remove do
  let(:user) { create(:user) }
  let(:subforem) { create(:subforem) }

  before do
    allow(Rails.cache).to receive(:delete)
    allow(Mailchimp::Bot).to receive(:new).and_return(double(manage_community_moderator_list: true))
    allow(described_class).to receive(:community_mod_newsletter_enabled?).and_return(true)
  end

  describe "#call" do
    context "when user has community mod newsletter enabled" do
      before do
        allow_any_instance_of(Users::NotificationSetting).to receive(:email_community_mod_newsletter?).and_return(true)
        allow_any_instance_of(Users::NotificationSetting).to receive(:update)
      end

      it "removes the subforem moderator role from the user" do
        expect_any_instance_of(User).to receive(:remove_role).with(:subforem_moderator, subforem)
        described_class.call(user, subforem)
      end

      it "updates the user's notification settings" do
        expect_any_instance_of(Users::NotificationSetting).to receive(:update).with(email_community_mod_newsletter: false)
        described_class.call(user, subforem)
      end

      it "clears the cache" do
        expect(Rails.cache).to receive(:delete).with("user-#{user.id}/subforem_moderators_list")
        described_class.call(user, subforem)
      end

      it "manages mailchimp list" do
        expect(Mailchimp::Bot).to receive(:new).with(user)
        described_class.call(user, subforem)
      end
    end

    context "when user does not have community mod newsletter enabled" do
      before do
        allow_any_instance_of(Users::NotificationSetting).to receive(:email_community_mod_newsletter?).and_return(false)
      end

      it "removes the subforem moderator role from the user" do
        expect_any_instance_of(User).to receive(:remove_role).with(:subforem_moderator, subforem)
        described_class.call(user, subforem)
      end

      it "does not update notification settings" do
        expect_any_instance_of(Users::NotificationSetting).not_to receive(:update)
        described_class.call(user, subforem)
      end
    end
  end
end
