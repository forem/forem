require "rails_helper"

RSpec.describe DigestMailer, type: :mailer do
  describe "#digest_email" do
    it "works correctly" do
      user = build_stubbed(:user)
      article = build_stubbed(:article)
      allow(article).to receive(:title).and_return("test title")
      email = described_class.digest_email(user, [article])

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq(["yo@dev.to"])
    end
  end
end
