require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#community_name" do
    it "equals to the community name" do
      allow(ApplicationConfig).to receive(:[]).with("COMMUNITY_NAME").and_return("SLOAN")
      expect(helper.community_name).to eq("SLOAN")
    end
  end

  describe "#community_qualified_name" do
    it "equals to the full qualified community name" do
      expected_name = "#{ApplicationConfig['COMMUNITY_NAME']} Community"
      expect(helper.community_qualified_name).to eq(expected_name)
    end
  end

  describe "#beautified_url" do
    it "strips the protocol" do
      expect(helper.beautified_url("https://github.com")).to eq("github.com")
    end

    it "strips params" do
      expect(helper.beautified_url("https://github.com?a=3")).to eq("github.com")
    end

    it "strips the last forward slash" do
      expect(helper.beautified_url("https://github.com/")).to eq("github.com")
    end

    it "does not strip the path" do
      expect(helper.beautified_url("https://github.com/rails")).to eq("github.com/rails")
    end
  end

  describe "#cache_key_heroku_slug" do
    it "does nothing when HEROKU_SLUG_COMMIT is not set" do
      allow(ApplicationConfig).to receive(:[]).with("HEROKU_SLUG_COMMIT").and_return(nil)
      expect(helper.cache_key_heroku_slug("cache-me")).to eq("cache-me")
    end

    it "appends the HEROKU_SLUG_COMMIT if it is set" do
      allow(ApplicationConfig).to receive(:[]).with("HEROKU_SLUG_COMMIT").and_return("abc123")
      expect(helper.cache_key_heroku_slug("cache-me")).to eq("cache-me-abc123")
    end
  end

  describe "#copyright_notice" do
    let(:current_year) { Time.current.year.to_s }

    context "when the start year and current year is the same" do
      it "returns the current year only" do
        allow(ApplicationConfig).to receive(:[]).with("COMMUNITY_COPYRIGHT_START_YEAR").and_return(current_year)
        expect(helper.copyright_notice).to eq(current_year)
      end
    end

    context "when the start year and current year is different" do
      it "returns the start and current year" do
        allow(ApplicationConfig).to receive(:[]).with("COMMUNITY_COPYRIGHT_START_YEAR").and_return("2014")
        expect(helper.copyright_notice).to eq("2014 - #{current_year}")
      end
    end

    context "when the start year is blank" do
      it "returns the current year" do
        allow(ApplicationConfig).to receive(:[]).with("COMMUNITY_COPYRIGHT_START_YEAR").and_return(" ")
        expect(helper.copyright_notice).to eq(current_year)
      end
    end
  end

  describe "#app_url" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("https://")
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("dev.to")
    end

    it "creates the correct base app URL" do
      expect(app_url).to eq("https://dev.to")
    end

    it "creates a URL with a path" do
      expect(app_url("internal")).to eq("https://dev.to/internal")
    end

    it "creates the correct URL even if the path starts with a slash" do
      expect(app_url("/internal")).to eq("https://dev.to/internal")
    end

    it "works when called with an URI object" do
      uri = URI::Generic.build(path: "internal", fragment: "test")
      expect(app_url(uri)).to eq("https://dev.to/internal#test")
    end
  end

  describe "#sanitized_referer" do
    it "returns a safe referrer unmodified" do
      expect(sanitized_referer("/some/path")).to eq("/some/path")
    end

    it "returns nil if the referer is the service worker" do
      expect(sanitized_referer("/serviceworker.js")).to be nil
    end

    it "returns nil if the referer is empty" do
      expect(sanitized_referer("")).to be nil
    end
  end

  describe "#email_link" do
    before do
      allow(SiteConfig).to receive(:email_addresses).and_return(
        {
          default: "hi@dev.to",
          business: "business@dev.to",
          privacy: "privacy@dev.to",
          members: "members@dev.to"
        },
      )
    end

    it "returns an 'a' tag" do
      expect(helper.email_link).to have_selector("a")
    end

    it "sets the correct href" do
      expect(helper.email_link).to have_link(href: "mailto:hi@dev.to")
      expect(helper.email_link(:business)).to have_link(href: "mailto:business@dev.to")
    end

    it "has the correct text in the a tag" do
      expect(helper.email_link(text: "Link Name")).to have_text("Link Name")
      expect(helper.email_link).to have_text("hi@dev.to")
    end

    it "returns the default email if it doesn't understand the type parameter" do
      expect(helper.email_link(:nonsense)).to have_link(href: "mailto:hi@dev.to")
    end

    it "returns an href with additional_info parameters" do
      additional_info = {
        subject: "This is a long subject",
        body: "This is a longer body with a question mark ? \n and a newline"
      }

      expect(email_link(text: "text", additional_info: additional_info)).to eq("<a href=\"mailto:hi@dev.to?body=This%20is%20a%20longer%20body%20with%20a%20question%20mark%20%3F%20%0A%20and%20a%20newline&amp;subject=This%20is%20a%20long%20subject\">text</a>")
    end
  end

  describe "#community_members_label" do
    before do
      allow(SiteConfig).to receive(:community_member_label).and_return("hobbyist")
    end

    it "returns the pluralized community_member_label" do
      expect(community_members_label).to eq("hobbyists")
    end
  end

  describe "#sanitize_and_decode" do
    it "Sanitize and decode string" do
      expect(helper.sanitize_and_decode("<script>alert('alert')</script>")).to eq("alert('alert')")
      expect(helper.sanitize_and_decode("&lt; hello")).to eq("< hello")
    end
  end
end
