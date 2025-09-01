require "rails_helper"

RSpec.describe SubforemModerators::Add do
  let(:user) { create(:user) }
  let(:subforem) { create(:subforem) }
  let(:notification_setting) { user.notification_setting }

  before do
    allow(NotifyMailer).to receive(:with).and_return(double(subforem_moderator_confirmation_email: double(deliver_now: true)))
    allow(SubforemModerators::AddTrustedRole).to receive(:call)
    allow(Rails.cache).to receive(:delete)
    allow(Mailchimp::Bot).to receive(:new).and_return(double(manage_community_moderator_list: true))
  end

  describe "#call" do
    context "when successful" do
      before do
        allow(notification_setting).to receive(:update).and_return(true)
      end

      it "adds the subforem moderator role to the user" do
        expect_any_instance_of(User).to receive(:add_role).with(:subforem_moderator, subforem)
        described_class.call(user.id, subforem.id)
      end

      it "updates the user's notification settings" do
        expect_any_instance_of(Users::NotificationSetting).to receive(:update).with(email_community_mod_newsletter: true)
        described_class.call(user.id, subforem.id)
      end

      it "calls AddTrustedRole" do
        expect(SubforemModerators::AddTrustedRole).to receive(:call).with(user)
        described_class.call(user.id, subforem.id)
      end

      it "sends confirmation email" do
        expect(NotifyMailer).to receive(:with).with(user: user, subforem: subforem)
        described_class.call(user.id, subforem.id)
      end

      it "clears the cache" do
        expect(Rails.cache).to receive(:delete).with("user-#{user.id}/subforem_moderators_list")
        described_class.call(user.id, subforem.id)
      end

      it "returns success result" do
        result = described_class.call(user.id, subforem.id)
        expect(result.success?).to be true
        expect(result.errors).to be_nil
      end
    end

    context "when notification setting update fails" do
      before do
        allow_any_instance_of(Users::NotificationSetting).to receive(:update).and_return(false)
        allow_any_instance_of(Users::NotificationSetting).to receive(:errors_as_sentence).and_return("Error message")
      end

      it "returns failure result with errors" do
        result = described_class.call(user.id, subforem.id)
        expect(result.success?).to be false
        expect(result.errors).to eq("Error message")
      end

      it "does not add the role" do
        expect_any_instance_of(User).not_to receive(:add_role)
        described_class.call(user.id, subforem.id)
      end
    end
  end
end
