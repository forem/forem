require "rails_helper"

RSpec.describe DigestMailer, type: :mailer do
  let(:user) { build_stubbed(:user) }
  let(:article) { build_stubbed(:article) }

  describe "#digest_email" do
    before do
      allow(article).to receive(:title).and_return("test title")
    end

    it "works correctly" do
      email = described_class.with(user: user, articles: [article]).digest_email

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([SiteConfig.email_addresses[:default]])
      expected_from = "#{SiteConfig.community_name} Digest <#{SiteConfig.email_addresses[:default]}>"
      expect(email["from"].value).to eq(expected_from)
    end

    it "includes the tracking pixel" do
      email = described_class.with(user: user, articles: [article]).digest_email
      expect(email.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.with(user: user, articles: [article]).digest_email
      expect(email.body).to include(CGI.escape("utm_medium=email"))
      expect(email.body).to include(CGI.escape("utm_source=digest_mailer"))
      expect(email.body).to include(CGI.escape("utm_campaign=digest_email"))
    end
  end
end
