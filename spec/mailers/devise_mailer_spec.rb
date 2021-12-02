require "rails_helper"

RSpec.describe DeviseMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "#reset_password_instructions" do
    let(:email) { described_class.reset_password_instructions(user, "test") }

    before do
      allow(Settings::General).to receive(:app_domain).and_return("funky-one-of-a-kind-domain-#{rand(100)}.com")
    end

    it "renders sender" do
      expected_from = "#{Settings::Community.community_name} <#{ForemInstance.email}>"
      expect(email["from"].value).to eq(expected_from)
    end

    it "renders proper URL" do
      expect(email.to_s).to include(Settings::General.app_domain)
    end
  end

  describe "#confirmation_instructions" do
    context "when it's a Forem creator" do
      let!(:creator) { create(:user, :super_admin, :creator) }
      let(:email) { described_class.confirmation_instructions(creator, "faketoken") }

      it "renders the correct body" do
        expect(email.body.to_s).to include("Hello! Once you've confirmed your email address, you'll be able to setup "\
                                           "your Forem Instance.")
      end

      it "renders proper URL" do
        expect(email.body.to_s).to include("/users/confirmation?confirmation_token=faketoken")
      end
    end

    context "when it's a user" do
      let(:email) { described_class.confirmation_instructions(user, "faketoken") }

      it "renders the correct body" do
        expect(email.to_s).to include("You can confirm your account email through the link below:")
      end

      it "renders proper URL" do
        expect(email.body.to_s).to include("/users/confirmation?confirmation_token=faketoken")
      end
    end
  end
end
