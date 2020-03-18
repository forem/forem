require "rails_helper"

RSpec.describe DigestMailer, type: :mailer do
  let(:user) { build_stubbed(:user) }
  let(:article) { build_stubbed(:article) }

  describe "#digest_email" do
    before do
      allow(article).to receive(:title).and_return("test title")
    end

    it "works correctly" do
      email = described_class.digest_email(user, [article])

      expect(email.subject).not_to be_nil
      expect(email.to).to eq([user.email])
      expect(email.from).to eq([SiteConfig.default_site_email])
      expect(email["from"].value).to eq("DEV Digest <#{SiteConfig.default_site_email}>")
    end

    it "includes the tracking pixel" do
      email = described_class.digest_email(user, [article])
      expect(email.body).to include("open.gif")
    end

    it "includes UTM params" do
      email = described_class.digest_email(user, [article])
      expect(email.body).to include(CGI.escape("utm_medium=email"))
      expect(email.body).to include(CGI.escape("utm_source=digest_mailer"))
      expect(email.body).to include(CGI.escape("utm_campaign=digest_email"))
    end
  end
end
