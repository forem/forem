require "rails_helper"

RSpec.describe DigestMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:article) { build_stubbed(:article) }

  describe "#digest_email" do
    before do
      allow(article).to receive(:title).and_return("test title")
    end

    it "works correctly" do
      email = described_class.with(user: user, articles: [article]).digest_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([ForemInstance.email])
      expected_from = "#{Settings::Community.community_name} Digest <#{ForemInstance.email}>"
      expect(email["from"].value).to eq(expected_from)
    end
  end
end
