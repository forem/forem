require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  include CloudinaryHelper

  describe "constant definitions" do
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

      expect(Class.new.include(described_class).new.subtitles).to eq subtitles
    end
  end

  describe "#community_name" do
    it "equals to the community name" do
      allow(Settings::Community).to receive(:community_name).and_return("SLOAN")
      expect(helper.community_name).to eq("SLOAN")
    end
  end

  describe "#display_navigation_link?" do
    subject(:method_call) { helper.display_navigation_link?(link: link) }

    let(:link) { build(:navigation_link, display_to: display_to) }

    before do
      allow(helper).to receive(:user_signed_in?).and_return(user_signed_in)
      allow(helper).to receive(:navigation_link_is_for_an_enabled_feature?)
        .with(link: link)
        .and_return(navigation_link_is_for_an_enabled_feature)
    end

    context "when user signed in and link requires signin and feature enabled" do
      let(:navigation_link_is_for_an_enabled_feature) { true }
      let(:display_to) { :logged_in }
      let(:user_signed_in) { true }

      it { is_expected.to be_truthy }
    end

    context "when user signed in and link requires signin and feature disabled" do
      let(:display_to) { :all }
      let(:user_signed_in) { true }
      let(:navigation_link_is_for_an_enabled_feature) { false }

      it { is_expected.to be_falsey }
    end

    context "when user signed in and link **does not** require signin and feature enabled" do
      let(:navigation_link_is_for_an_enabled_feature) { true }
      let(:display_to) { :all }
      let(:user_signed_in) { true }

      it { is_expected.to be_truthy }
    end

    context "when user signed in and link requires signout and feature enabled" do
      let(:navigation_link_is_for_an_enabled_feature) { true }
      let(:display_to) { :logged_out }
      let(:user_signed_in) { true }

      it { is_expected.to be_falsey }
    end

    context "when user signed in and link requires signout and feature disabled" do
      let(:navigation_link_is_for_an_enabled_feature) { false }
      let(:display_to) { :logged_out }
      let(:user_signed_in) { true }

      it { is_expected.to be_falsey }
    end

    context "when user signed in and link **does not** require signin and feature disabled" do
      let(:navigation_link_is_for_an_enabled_feature) { false }
      let(:display_to) { :all }
      let(:user_signed_in) { true }

      it { is_expected.to be_falsey }
    end

    context "when user **not** signed in and link requires signin and feature enabled" do
      let(:navigation_link_is_for_an_enabled_feature) { true }
      let(:display_to) { :logged_in }
      let(:user_signed_in) { false }

      it { is_expected.to be_falsey }
    end

    context "when user **not** signed in and link **does not** require signin and feature enabled" do
      let(:navigation_link_is_for_an_enabled_feature) { true }
      let(:display_to) { :all }
      let(:user_signed_in) { false }

      it { is_expected.to be_truthy }
    end

    context "when user **not** signed in and link **does not** require signin and feature disabled" do
      let(:navigation_link_is_for_an_enabled_feature) { false }
      let(:display_to) { :all }
      let(:user_signed_in) { false }

      it { is_expected.to be_falsey }
    end

    context "when user **not** signed in and link requires signout and feature enabled" do
      let(:navigation_link_is_for_an_enabled_feature) { true }
      let(:display_to) { :logged_out }
      let(:user_signed_in) { false }

      it { is_expected.to be_truthy }
    end

    context "when user **not** signed in and link requires signout and feature disabled" do
      let(:navigation_link_is_for_an_enabled_feature) { false }
      let(:display_to) { :logged_out }
      let(:user_signed_in) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe "#navigation_link_is_for_an_enabled_feature?" do
    subject(:method_call) { helper.navigation_link_is_for_an_enabled_feature?(link: link) }

    let(:url) { URL.url("/somehwere") }
    let(:link) { build(:navigation_link, url: url) }

    context "when Listing feature is enabled" do
      before { allow(Listing).to receive(:feature_enabled?).and_return(true) }

      it { is_expected.to be_truthy }
    end

    context "when Listing feature is disabled and link not for listing" do
      before { allow(Listing).to receive(:feature_enabled?).and_return(false) }

      it { is_expected.to be_truthy }
    end

    context "when Listing feature is disabled and link is for /listings" do
      let(:url) { URL.url("/listings") }

      before { allow(Listing).to receive(:feature_enabled?).and_return(false) }

      it { is_expected.to be_falsey }
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

    it "includes Settings::General.admin_action_taken_at" do
      Timecop.freeze do
        allow(Settings::General).to receive(:admin_action_taken_at).and_return(5.minutes.ago)
        allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("abc123")
        expect(helper.release_adjusted_cache_key("cache-me"))
          .to include(Settings::General.admin_action_taken_at.rfc3339)
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
      allow(Settings::General).to receive(:app_domain).and_return("dev.to")
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
      uri = URI::Generic.build(path: "resource_admin", fragment: "test").to_s
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

  describe "#contact_link" do
    let(:default_email) { "hi@dev.to" }

    before do
      allow(ForemInstance).to receive(:contact_email).and_return(default_email)
    end

    it "returns an 'a' tag" do
      expect(helper.contact_link).to have_selector("a")
    end

    it "sets the correct href" do
      expect(helper.contact_link).to have_link(href: "mailto:#{default_email}")
    end

    it "has the correct text in the a tag" do
      expect(helper.contact_link(text: "Link Name")).to have_text("Link Name")
      expect(helper.contact_link).to have_text(default_email)
    end

    it "returns an href with additional_info parameters" do
      additional_info = {
        subject: "This is a long subject",
        body: "This is a longer body with a question mark ? \n and a newline"
      }

      link = "<a href=\"mailto:#{default_email}?body=This%20is%20a%20longer%20body%20with%20a%20" \
             "question%20mark%20%3F%20%0A%20and%20a%20newline&amp;subject=This%20is%20a%20long%20subject\">text</a>"
      expect(contact_link(text: "text", additional_info: additional_info)).to eq(link)
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

  describe "#cloudinary", cloudinary: true do
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
    it "works just like cl_image_tag", cloudinary: true do
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

  describe "#application_policy_content_tag" do
    subject(:content) do
      application_policy_content_tag("p", record: Article, query: :create?, class: "something") do
        "My Content"
      end
    end

    it "adds the policy related classes to the HTML tag element element" do
      expect(content).to include(%(<p class="something js-policy-article-create">My Content</p>))
    end
  end
end
