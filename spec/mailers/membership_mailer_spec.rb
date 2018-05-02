require "rails_helper"

RSpec.describe MembershipMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "#new_membership_subscription_email" do
    it "renders proper subject" do
      user = create(:user)
      new_membership_subscription_email = described_class.new_membership_subscription_email(user, "level_1_member")
      expect(new_membership_subscription_email.subject).to include("Thanks for subscribing")
    end
    it "renders proper receiver" do
      user = create(:user)
      new_membership_subscription_email = described_class.new_membership_subscription_email(user, "level_1_member")
      expect(new_membership_subscription_email.to).to eq([user.email])
    end
  end

  describe "#subscription_cancellation_email" do
    it "renders proper subject" do
      user = create(:user)
      subscription_cancellation_email = described_class.subscription_cancellation_email(user)
      expect(subscription_cancellation_email.subject).to include("Sorry to lose you")
    end
    it "renders proper receiver" do
      user = create(:user)
      subscription_cancellation_email = described_class.subscription_cancellation_email(user)
      expect(subscription_cancellation_email.to).to eq([user.email])
    end
  end
end
