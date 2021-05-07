require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  include CloudinaryHelper

  describe "constant definitions" do
    it "defines USER_COLORS" do
      expect(described_class::USER_COLORS).to eq ["#19063A", "#dce9f3"]
    end

    it "defines DELETED_USER" do
      user = described_class::DELETED_USER
      expect(user).not_to be_nil
      expect(user.darker_color).to eq Color::CompareHex.new(described_class::USER_COLORS).brightness
      expect(user.username).to eq "[deleted user]"
      expect(user.name).to eq "[Deleted User]"
      expect(user.summary).to be_nil
      expect(user.twitter_username).to be_nil
      expect(user.github_username).to be_nil
    end

    it "defines LARGE_USERBASE_THRESHOLD" do
      expect(described_class::LARGE_USERBASE_THRESHOLD).to eq 1000
    end

    it "defines SUBTITLES" do
      subtitles = {
        "week" => "Top posts this week",
        "month" => "Top posts this month",
        "year" => "Top posts this year",
        "infinity" => "All posts",
        "latest" => "Latest posts"
      }

      expect(described_class::SUBTITLES).to eq subtitles
    end
  end

  describe "#community_name" do
    it "equals to the community name" do
      allow(Settings::Community).to receive(:community_name).and_return("SLOAN")
      expect(helper.community_name).to eq("SLOAN")
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

  describe "#release_adjusted_cache_key" do
    after { ForemInstance.instance_variable_set(:@deployed_at, nil) }

    it "does nothing when RELEASE_FOOTPRINT is not set" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return(nil)
      expect(helper.release_adjusted_cache_key("cache-me")).to include("cache-me")
    end

    it "appends the RELEASE_FOOTPRINT if it is set" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("abc123")
      expect(helper.release_adjusted_cache_key("cache-me")).to include("cache-me--abc123")
    end

    it "includes locale param if it is set" do
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("abc123")
      params[:locale] = "fr-ca"
      expect(helper.release_adjusted_cache_key("cache-me")).to include("cache-me-fr-ca-abc123")
    end

    it "includes SiteConfig.admin_action_taken_at" do
      Timecop.freeze do
        allow(SiteConfig).to receive(:admin_action_taken_at).and_return(5.minutes.ago)
        allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("abc123")
        expect(helper.release_adjusted_cache_key("cache-me")).to include(SiteConfig.admin_action_taken_at.rfc3339)
      end
    end
  end

  describe "#copyright_notice" do
    let(:current_year) { Time.current.year.to_s }

    context "when the start year and current year is the same" do
      it "returns the current year only" do
        allow(Settings::Community).to receive(:copyright_start_year).and_return(current_year)
        expect(helper.copyright_notice).to eq(current_year)
      end
    end

    context "when the start year and current year is different" do
      it "returns the start and current year" do
        allow(Settings::Community).to receive(:copyright_start_year).and_return("2014")
        expect(helper.copyright_notice).to eq("2014 - #{current_year}")
      end
    end

    context "when the start year is blank" do
      it "returns the current year" do
        allow(Settings::Community).to receive(:copyright_start_year).and_return(" ")
        expect(helper.copyright_notice).to eq(current_year)
      end
    end
  end

  describe "#app_url" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("https://")
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("dev.to")
      allow(SiteConfig).to receive(:app_domain).and_return("dev.to")
    end

    it "creates the correct base app URL" do
      expect(app_url).to eq("https://dev.to")
    end

    it "creates a URL with a path" do
      expect(app_url("admin")).to eq("https://dev.to/admin")
    end

    it "creates the correct URL even if the path starts with a slash" do
      expect(app_url("/admin")).to eq("https://dev.to/admin")
    end

    it "works when called with an URI object" do
      uri = URI::Generic.build(path: "resource_admin", fragment: "test")
      expect(app_url(uri)).to eq("https://dev.to/resource_admin#test")
    end
  end

  describe "#collection_link" do
    let(:collection) { create(:collection, :with_articles) }

    it "returns an 'a' tag" do
      expect(helper.collection_link(collection)).to have_selector("a")
    end

    it "sets the correct href" do
      expect(helper.collection_link(collection)).to have_link(href: collection.path)
    end

    it "has the correct text in the a tag" do
      expect(helper.collection_link(collection))
        .to have_text("#{collection.slug} (#{collection.articles.published.size} Part Series)")
    end
  end

  describe "#email_link" do
    let(:contact_email) { "contact@dev.to" }

    before do
      allow(SiteConfig).to receive(:email_addresses).and_return(
        {
          default: "hi@dev.to",
          contact: contact_email,
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
      expect(helper.email_link).to have_link(href: "mailto:#{contact_email}")
      expect(helper.email_link(:business)).to have_link(href: "mailto:business@dev.to")
    end

    it "has the correct text in the a tag" do
      expect(helper.email_link(text: "Link Name")).to have_text("Link Name")
      expect(helper.email_link).to have_text(contact_email)
    end

    it "returns the default email if it doesn't understand the type parameter" do
      expect(helper.email_link(:nonsense)).to have_link(href: "mailto:#{contact_email}")
    end

    it "returns an href with additional_info parameters" do
      additional_info = {
        subject: "This is a long subject",
        body: "This is a longer body with a question mark ? \n and a newline"
      }

      link = "<a href=\"mailto:#{contact_email}?body=This%20is%20a%20longer%20body%20with%20a%20" \
        "question%20mark%20%3F%20%0A%20and%20a%20newline&amp;subject=This%20is%20a%20long%20subject\">text</a>"
      expect(email_link(text: "text", additional_info: additional_info)).to eq(link)
    end
  end

  describe "#community_members_label" do
    before do
      allow(Settings::Community).to receive(:member_label).and_return("hobbyist")
    end

    it "returns the pluralized community_member_label" do
      expect(community_members_label).to eq("hobbyists")
    end
  end

  describe "#sanitize_and_decode" do
    it "sanitize and decode string" do
      expect(helper.sanitize_and_decode("<script>alert('alert')</script>")).to eq("alert('alert')")
      expect(helper.sanitize_and_decode("&lt; hello")).to eq("< hello")
    end
  end

  describe "#cloudinary" do
    it "returns cloudinary-manipulated link" do
      image = helper.optimized_image_url(Faker::Placeholdit.image)
      expect(image).to start_with("https://res.cloudinary.com")
        .and include("image/fetch/", "/c_limit,f_auto,fl_progressive,q_80,w_500/")
    end

    it "returns an ASCII domain for Unicode input" do
      expect(helper.optimized_image_url("https://www.火.dev/IMAGE.png")).to include("https://www.xn--vnx.dev/IMAGE.png")
    end

    it "keeps an ASCII domain as ASCII" do
      expect(helper.optimized_image_url("https://www.xn--vnx.dev/image.png")).to include("https://www.xn--vnx.dev")
    end

    it "returns random fallback images as expected" do
      expect(helper.optimized_image_url("")).not_to be_nil
      expect(helper.optimized_image_url("", random_fallback: false)).to be_nil
    end
  end

  describe "#optimized_image_tag" do
    it "works just like cl_image_tag" do
      image_url = "https://i.imgur.com/fKYKgo4.png"
      cloudinary_image_tag = cl_image_tag(image_url,
                                          type: "fetch", crop: "imagga_scale",
                                          quality: "auto", flags: "progressive",
                                          fetch_format: "auto", sign_url: true,
                                          loading: "lazy", alt: "profile image",
                                          width: 100, height: 100)
      optimized_helper = helper.optimized_image_tag(image_url,
                                                    optimizer_options: { crop: "imagga_scale", width: 100,
                                                                         height: 100 },
                                                    image_options: { loading: "lazy", alt: "profile image" })
      expect(optimized_helper).to eq(cloudinary_image_tag)
    end
  end
end
