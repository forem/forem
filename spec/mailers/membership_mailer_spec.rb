require "rails_helper"

RSpec.describe MembershipMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "#new_membership_subscription_email" do
    it "renders proper subject" do
      email = described_class.new_membership_subscription_email(user, "level_1_member")
      expect(email.subject).to include("Thanks for subscribing")
    end

    it "renders proper receiver" do
      email = described_class.new_membership_subscription_email(user, "level_1_member")
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.new_membership_subscription_email(user, "level_1_member")
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.new_membership_subscription_email(user, "level_1_member")
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=membership_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=new_membership_subscription_email"))
    end
  end

  describe "#subscription_update_confirm_email" do
    it "renders proper subject" do
      email = described_class.subscription_update_confirm_email(user)
      expect(email.subject).to include("Your subscription has been updated.")
    end

    it "renders proper receiver" do
      email = described_class.subscription_update_confirm_email(user)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.subscription_update_confirm_email(user)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.subscription_update_confirm_email(user)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=membership_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=subscription_update_confirm_email"))
    end
  end

  describe "#subscription_cancellation_email" do
    it "renders proper subject" do
      email = described_class.subscription_cancellation_email(user)
      expect(email.subject).to include("Sorry to lose you")
    end

    it "renders proper receiver" do
      email = described_class.subscription_cancellation_email(user)
      expect(email.to).to eq([user.email])
    end

    it "includes the tracking pixel" do
      email = described_class.subscription_cancellation_email(user)
      expect(email.html_part.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.subscription_cancellation_email(user)
      expect(email.html_part.body).to include(CGI.escape("utm_medium=email"))
      expect(email.html_part.body).to include(CGI.escape("utm_source=membership_mailer"))
      expect(email.html_part.body).to include(CGI.escape("utm_campaign=subscription_cancellation_email"))
    end
  end
end
