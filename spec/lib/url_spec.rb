require "rails_helper"

RSpec.describe URL, type: :lib do
  before do
    allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("https://")
    allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("test.forem.cloud")
    allow(SiteConfig).to receive(:app_domain).and_return("dev.to")
  end

  describe ".protocol" do
    it "returns the value of APP_PROTOCOL env variable" do
      expect(described_class.protocol).to eq(ApplicationConfig["APP_PROTOCOL"])
    end
  end

  describe ".domain" do
    it "returns the value of SiteConfig" do
      expect(described_class.domain).to eq(SiteConfig.app_domain)
    end
  end

  describe ".url" do
    it "creates the correct base app URL" do
      expect(described_class.url).to eq("https://dev.to")
    end

    it "creates a URL with a path" do
      expect(described_class.url("admin")).to eq("https://dev.to/admin")
    end

    it "creates the correct URL even if the path starts with a slash" do
      expect(described_class.url("/admin")).to eq("https://dev.to/admin")
    end

    it "works when called with an URI object" do
      uri = URI::Generic.build(path: "admin", fragment: "test")
      expect(described_class.url(uri)).to eq("https://dev.to/admin#test")
    end
  end

  describe ".article" do
    let(:article) { build(:article, path: "/username1/slug") }

    it "returns the correct URL for an article" do
      expect(described_class.article(article)).to eq("https://dev.to#{article.path}")
    end
  end

  describe ".comment" do
    let(:comment) { build(:comment) }

    it "returns the correct URL for a comment" do
      expect(described_class.comment(comment)).to eq("https://dev.to#{comment.path}")
    end
  end

  describe ".reaction" do
    it "returns the correct URL for an article's reaction" do
      article = build(:article, path: "/username1/slug")
      reaction = build(:reaction, reactable: article)
      expect(described_class.reaction(reaction)).to eq("https://dev.to#{article.path}")
    end

    it "returns the correct URL for a comment's reaction" do
      comment = build(:comment)
      reaction = build(:reaction, reactable: comment)
      expect(described_class.reaction(reaction)).to eq("https://dev.to#{comment.path}")
    end
  end

  describe ".user" do
    let(:user) { build(:user) }

    it "returns the correct URL for a user" do
      expect(described_class.user(user)).to eq("https://dev.to/#{user.username}")
    end
  end

  describe ".organization" do
    let(:organization) { build(:organization) }

    it "returns the correct URL for a user" do
      expect(described_class.user(organization)).to eq("https://dev.to/#{organization.slug}")
    end
  end

  describe ".tag" do
    let(:tag) { build(:tag) }

    it "returns the correct URL for a tag with no page" do
      expect(described_class.tag(tag)).to eq("https://dev.to/t/#{tag.name}")
    end

    it "returns the correct URL for a tag" do
      expect(described_class.tag(tag, 2)).to eq("https://dev.to/t/#{tag.name}/page/2")
    end
  end

  describe ".deep_link" do
    it "returns the correct URL for the root path" do
      expect(described_class.deep_link("/")).to eq("https://forem-udl-server.herokuapp.com/?r=https%3A%2F%2Fdev.to%2Fr%2Fmobile%3Fdeep_link%3D%2F")
    end

    it "returns the correct URL for an explicit path" do
      expect(described_class.deep_link("/sloan")).to eq("https://forem-udl-server.herokuapp.com/?r=https%3A%2F%2Fdev.to%2Fr%2Fmobile%3Fdeep_link%3D%2Fsloan")
    end
  end

  describe ".local_image" do
    let(:image_name) { "social-media-cover" }
    let(:image_extension) { ".png" }
    let(:image_file) { image_name + image_extension }
    let(:test_host) { "https://test-host.com" }

    # Rails "fingerprints" the assets so /social-media-cover.png is actually
    # /social-media-cover-a1b2c3.png. Therefore, we use regex to match the file
    # names in these specs.
    it "returns the correct URL for an image name with no host" do
      image_url_regex = %r{
        #{ApplicationConfig["APP_PROTOCOL"]} # https://
        #{SiteConfig.app_domain}/            # dev.to
        assets/                              # assets/ directory
        #{image_name}-                       # social-media-cover
        [a-f0-9]*                            # letters and numbers
        #{image_extension}                   # .png
      }x
      expect(described_class.local_image(image_file)).to match(image_url_regex)
    end

    it "returns the correct URL for an image when a host is provided" do
      image_url_regex = %r{
        #{test_host}/      # https://test-host.com
        assets/            # assets/ directory
        #{image_name}-     # social-media-cover
        [a-f0-9]*          # letters and numbers
        #{image_extension} # .png
      }x
      expect(described_class.local_image(image_file, host: test_host)).to match(image_url_regex)
    end

    it "returns the correct URL for an image when an asset_host is defined" do
      allow(ActionController::Base).to receive(:asset_host).and_return(test_host)
      image_url_regex = %r{
        #{test_host}/      # https://test-host.com
        assets/            # assets/ directory
        #{image_name}-     # social-media-cover
        [a-f0-9]*          # letters and numbers
        #{image_extension} # .png
      }x
      expect(described_class.local_image(image_file)).to match(image_url_regex)
    end
  end
end
