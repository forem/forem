require "rails_helper"

RSpec.describe DigestMailer do
  let(:user) { create(:user) }
  let(:article) { build_stubbed(:article) }
  let(:from_email_address) { "custom_noreply@forem.com" }

  describe "#digest_email" do
    before do
      allow(article).to receive(:title).and_return("test title")
      allow(Settings::SMTP).to receive(:provided_minimum_settings?).and_return(true)
      allow(Settings::SMTP).to receive(:from_email_address).and_return(from_email_address)
    end

    it "works correctly", :aggregate_failures do
      email = described_class.with(user: user, articles: [article]).digest_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([from_email_address])
      expected_from = "#{Settings::Community.community_name} Digest <#{from_email_address}>"
      expect(email["from"].value).to eq(expected_from)
    end
  end
end
