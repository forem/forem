require "rails_helper"

RSpec.describe Images::Optimizer, type: :service do
  include CloudinaryHelper

  let(:image_url) { "https://i.imgur.com/fKYKgo4.png" }

  describe "#call" do
    before do
      allow(described_class).to receive(:cloudinary)
      allow(described_class).to receive(:cloudflare)
      allow(described_class).to receive(:imgproxy)
    end

    it "does nothing when given a relative url" do
      relative_asset_path = "/assets/something.jpg"
      expect(described_class.call(relative_asset_path)).to eq(relative_asset_path)
    end

    it "does nothing when given nil" do
      expect(described_class.call(nil)).to be_nil
    end

    it "returns the image if neither cloudinary nor imgproxy are enabled", :aggregate_failures do
      allow(described_class).to receive(:cloudinary_enabled?).and_return(false)
      allow(described_class).to receive(:imgproxy_enabled?).and_return(false)

      expect(described_class.call(image_url)).to eq(image_url)

      expect(described_class).not_to have_received(:cloudinary)
      expect(described_class).not_to have_received(:imgproxy)
    end

    it "calls cloudinary if imgproxy is not enabled" do
      allow(described_class).to receive(:cloudinary_enabled?).and_return(true)
      allow(described_class).to receive(:imgproxy_enabled?).and_return(false)

      described_class.call(image_url)

      expect(described_class).to have_received(:cloudinary)
      expect(described_class).not_to have_received(:imgproxy)
    end

    it "calls imgproxy if imgproxy is enabled" do
      allow(described_class).to receive(:cloudinary_enabled?).and_return(true)
      allow(described_class).to receive(:imgproxy_enabled?).and_return(true)

      described_class.call(image_url)

      expect(described_class).not_to have_received(:cloudinary)
      expect(described_class).to have_received(:imgproxy)
    end
  end

  describe "#cloudinary", cloudinary: true do
    it "performs exactly like cl_image_path" do
      cloudinary_url = cl_image_path(image_url,
                                     type: "fetch",
                                     width: 50, height: 50,
                                     crop: "fill",
                                     quality: "auto",
                                     flags: "progressive",
                                     fetch_format: "auto",
                                     sign_url: true)
      expect(described_class.call(image_url, width: 50, height: 50, crop: "crop")).to eq(cloudinary_url)
    end

    it "generates correct url by relying on DEFAULT_CL_OPTIONS" do
      cloudinary_url = cl_image_path(image_url,
                                     type: "fetch",
                                     quality: "auto",
                                     crop: "limit",
                                     sign_url: true,
                                     flags: "progressive",
                                     fetch_format: "jpg")
      expect(described_class.call(image_url, fetch_format: "jpg")).to eq(cloudinary_url)
    end

    it "generates correct crop with 'crop' passed" do
      cloudinary_url = cl_image_path(image_url,
                                     type: "fetch",
                                     quality: "auto",
                                     sign_url: true,
                                     crop: "fill",
                                     flags: "progressive",
                                     fetch_format: "jpg")
      expect(described_class.call(image_url, crop: "crop", fetch_format: "jpg")).to eq(cloudinary_url)
    end

    it "generates correct crop with 'limit' passed" do
      cloudinary_url = cl_image_path(image_url,
                                     type: "fetch",
                                     quality: "auto",
                                     sign_url: true,
                                     crop: "limit",
                                     flags: "progressive",
                                     fetch_format: "jpg")
      expect(described_class.call(image_url, crop: "limit", fetch_format: "jpg")).to eq(cloudinary_url)
    end

    it "generates correct crop with 'jiberish' passed" do
      cloudinary_url = cl_image_path(image_url,
                                     type: "fetch",
                                     quality: "auto",
                                     sign_url: true,
                                     crop: "limit",
                                     flags: "progressive",
                                     fetch_format: "jpg")
      expect(described_class.call(image_url, crop: "jiberish", fetch_format: "jpg")).to eq(cloudinary_url)
    end

    it "generates correct crop when CROP_WITH_IMAGGA_SCALE is set" do
      allow(ApplicationConfig).to receive(:[]).with("CROP_WITH_IMAGGA_SCALE").and_return("true")
      cloudinary_url = cl_image_path(image_url,
                                     type: "fetch",
                                     quality: "auto",
                                     sign_url: true,
                                     crop: "imagga_scale",
                                     flags: "progressive",
                                     fetch_format: "jpg")
      expect(described_class.call(image_url, crop: "crop", fetch_format: "jpg")).to eq(cloudinary_url)
    end

    it "generates correct crop when CROP_WITH_IMAGGA_SCALE is set but never_imagga: true is passed" do
      allow(ApplicationConfig).to receive(:[]).with("CROP_WITH_IMAGGA_SCALE").and_return("true")
      cl_url = cl_image_path(image_url,
                                     type: "fetch",
                                     quality: "auto",
                                     sign_url: true,
                                     crop: "fill",
                                     flags: "progressive",
                                     fetch_format: "jpg")
      expect(described_class.call(image_url, crop: "crop", fetch_format: "jpg", never_imagga: true)).to eq(cl_url)
    end
  end

  describe "#imgproxy" do
    before do
      allow(described_class).to receive(:imgproxy_enabled?).and_return(true)
    end

    it "generates correct url with crop default" do
      imgproxy_url = described_class.imgproxy(image_url, width: 500, height: 500)
      # mb = maximum bytes, defaults to 500_000 bytes
      # ar = autorotate, defaults to "true", serialized as "1"
      expect(imgproxy_url).to match(%r{/rs:fit:500:500/g:sm/mb:500000/ar:1/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end

    it "generates correct crop with 'crop' passed" do
      imgproxy_url = described_class.imgproxy(image_url, width: 500, height: 500, crop: "crop")
      expect(imgproxy_url).to match(%r{/rs:fill:500:500/g:sm/mb:500000/ar:1/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end

    it "generates correct crop with 'crop' passed, and never_imagga" do
      imgproxy_url = described_class.imgproxy(image_url, width: 500, height: 500, crop: "crop", never_imagga: true)
      expect(imgproxy_url).to match(%r{/rs:fill:500:500/g:sm/mb:500000/ar:1/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end

    it "generates correct crop with 'limit' passed" do
      imgproxy_url = described_class.imgproxy(image_url, width: 500, height: 500, crop: "limit")
      expect(imgproxy_url).to match(%r{/rs:fit:500:500/g:sm/mb:500000/ar:1/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end

    it "generates correct crop with 'jiberish' passed" do
      imgproxy_url = described_class.imgproxy(image_url, width: 500, height: 500, crop: "jiberish")
      expect(imgproxy_url).to match(%r{/rs:fit:500:500/g:sm/mb:500000/ar:1/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end
  end

  describe "#cloudflare" do
    let(:cloudfare_domain) { ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"] }
    let(:cloudfare_basic_url) { "https://#{cloudfare_domain}/cdn-cgi/image/width=821,height=900,fit=cover,gravity=auto,format=auto/" }

    before do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_IMAGES_DOMAIN").and_return("images.example.com")
    end

    it "generates correct url based on h/w input" do
      cloudflare_url = described_class.cloudflare(image_url, width: 821, height: 505, crop: "limit")
      url_regexp = %r{/width=821,height=505,fit=scale-down,gravity=auto,format=auto/#{CGI.escape(image_url)}}
      expect(cloudflare_url).to match(url_regexp)
    end

    it "generates correct url with crop default" do
      cloudflare_url = described_class.cloudflare(image_url, width: 821, height: 420)
      url_regexp = %r{/width=821,height=420,fit=scale-down,gravity=auto,format=auto/#{CGI.escape(image_url)}}
      expect(cloudflare_url).to match(url_regexp)
    end


    it "generates correct crop with 'crop' passed" do
      cloudflare_url = described_class.cloudflare(image_url, width: 821, height: 420, crop: "crop")
      url_regexp = %r{/width=821,height=420,fit=cover,gravity=auto,format=auto/#{CGI.escape(image_url)}}
      expect(cloudflare_url).to match(url_regexp)
    end

    it "generates correct crop with 'limit' passed" do
      cloudflare_url = described_class.cloudflare(image_url, width: 821, height: 420, crop: "limit")
      url_regexp = %r{/width=821,height=420,fit=scale-down,gravity=auto,format=auto/#{CGI.escape(image_url)}}
      expect(cloudflare_url).to match(url_regexp)
    end

    it "generates correct crop with 'jiberish' passed" do
      cloudflare_url = described_class.cloudflare(image_url, width: 821, height: 420, crop: "jiberish")
      url_regexp = %r{/width=821,height=420,fit=scale-down,gravity=auto,format=auto/#{CGI.escape(image_url)}}
      expect(cloudflare_url).to match(url_regexp)
    end

    it "does not error if nil" do
      cloudflare_url = described_class.cloudflare(nil, width: 821, height: 420, crop: "limit")
      expect(cloudflare_url).to match(%r{/width=821,height=420,fit=scale-down,gravity=auto,format=auto/})
    end

    it "pulls suffix if nested cloudflare url is provided" do
      cloudflare_url = described_class.cloudflare(
        [cloudfare_basic_url, CGI.escape(image_url)].join,
        width: 821, height: 420,
      )
      expect(cloudflare_url).to eq("https://#{cloudfare_domain}/cdn-cgi/image/width=821,height=420,fit=scale-down,gravity=auto,format=auto/#{CGI.escape(image_url)}")
    end

    it "does not error out if image is empty" do
      cloudflare_url = described_class.cloudflare(
        cloudfare_basic_url,
        width: 821, height: 420,
      )
      expect(cloudflare_url).to eq("https://#{cloudfare_domain}/cdn-cgi/image/width=821,height=420,fit=scale-down,gravity=auto,format=auto/")
    end

    it "does not error out if image is not proper url and has https" do
      image_url = "https:hello"
      cloudflare_url = described_class.cloudflare(
        [cloudfare_basic_url, CGI.escape(image_url)].join,
        width: 821, height: 420,
      )
      expect(cloudflare_url).to eq("https://#{cloudfare_domain}/cdn-cgi/image/width=821,height=420,fit=scale-down,gravity=auto,format=auto/https%3Ahello")
    end

    it "does not error out if image is not proper url and does not have https" do
      image_url = "hello"
      cloudflare_url = described_class.cloudflare(
        [cloudfare_basic_url, CGI.escape(image_url)].join,
        width: 821, height: 420,
      )
      expect(cloudflare_url).to eq("https://#{cloudfare_domain}/cdn-cgi/image/width=821,height=420,fit=scale-down,gravity=auto,format=auto/")
    end
  end

  describe "#cloudinary_enabled?" do
    it "returns false if cloud_name, api_key or api_secret are missing", :aggregate_failures do
      allow(Cloudinary.config).to receive(:cloud_name).and_return("")
      expect(described_class.cloudinary_enabled?).to be(false)

      allow(Cloudinary.config).to receive(:cloud_name).and_return("cloud name")
      allow(Cloudinary.config).to receive(:api_key).and_return("")
      expect(described_class.cloudinary_enabled?).to be(false)

      allow(Cloudinary.config).to receive(:cloud_name).and_return("cloud name")
      allow(Cloudinary.config).to receive(:api_key).and_return("api key")
      allow(Cloudinary.config).to receive(:api_secret).and_return("")
      expect(described_class.cloudinary_enabled?).to be(false)
    end

    it "returns true if cloud_name and api_key and api_secret are provided" do
      allow(Cloudinary.config).to receive(:cloud_name).and_return("cloud name")
      allow(Cloudinary.config).to receive(:api_key).and_return("api key")
      allow(Cloudinary.config).to receive(:api_secret).and_return("api secret")

      expect(described_class.cloudinary_enabled?).to be(true)
    end
  end

  describe "#imgproxy_enabled?" do
    it "returns false if key and salt are missing" do
      allow(Imgproxy).to receive(:config).and_return(Imgproxy::Config.new)
      expect(described_class.imgproxy_enabled?).to be(false)
    end

    it "returns true if key and salt are provided" do
      imgproxy_config_stub = Imgproxy::Config.new.tap do |config|
        config.key = "secret"
        config.salt = "secret"
        config.base64_encode_urls = true
      end
      allow(Imgproxy).to receive(:config).and_return(imgproxy_config_stub)

      expect(described_class.imgproxy_enabled?).to be(true)
    end
  end

  describe "#cloudflare_enabled?" do
    it "returns false if config missing" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_IMAGES_DOMAIN").and_return(nil)
      expect(described_class.cloudflare_enabled?).to be(false)
    end

    it "returns true if config is present" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_IMAGES_DOMAIN").and_return("images.com")
      expect(described_class.cloudflare_enabled?).to be(true)
    end
  end

  describe "#translate_cloudinary_options" do
    it "sets resizing_type to fit if crop: jiberish is provided" do
      options = { width: 100, height: 100, crop: "jiberish" }
      expect(described_class.translate_cloudinary_options(options)).to include(resizing_type: "fit")
    end
  end
end
