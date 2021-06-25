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
end
