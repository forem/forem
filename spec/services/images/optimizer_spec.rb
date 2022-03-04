require "rails_helper"

RSpec.describe Images::Optimizer, type: :service do
  include CloudinaryHelper

  let(:image_url) { "https://i.imgur.com/fKYKgo4.png" }

  describe "#call" do
    before do
      allow(described_class).to receive(:cloudinary)
      allow(described_class).to receive(:imgproxy)
    end

    it "does nothing when given a relative url" do
      relative_asset_path = "/assets/something.jpg"
      expect(described_class.call(relative_asset_path)).to eq(relative_asset_path)
    end

    it "does nothing when given nil" do
      expect(described_class.call(nil)).to be(nil)
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
                                     crop: "imagga_scale",
                                     quality: "auto",
                                     flags: "progressive",
                                     fetch_format: "auto",
                                     sign_url: true)
      expect(described_class.call(image_url, width: 50, height: 50, crop: "imagga_scale")).to eq(cloudinary_url)
    end

    it "generates correct url by relying on DEFAULT_CL_OPTIONS" do
      cloudinary_url = cl_image_path(image_url,
                                     type: "fetch",
                                     quality: "auto",
                                     sign_url: true,
                                     flags: "progressive",
                                     fetch_format: "jpg")
      expect(described_class.call(image_url, crop: nil, fetch_format: "jpg")).to eq(cloudinary_url)
    end
  end

  describe "#imgproxy" do
    it "works" do
      allow(described_class).to receive(:imgproxy_enabled?).and_return(true)
      imgproxy_url = described_class.imgproxy(image_url, width: 500, height: 500)
      # mb = maximum bytes, defaults to 500_000 bytes
      # ar = autorotate, defaults to "true", serialized as "1"
      expect(imgproxy_url).to match(%r{/s:500:500/mb:500000/ar:1/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
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

  describe "#translate_cloudinary_options" do
    it "sets resizing_type to fill if crop: fill is provided" do
      options = { width: 100, height: 100, crop: "fill" }
      expect(described_class.translate_cloudinary_options(options)).to include(resizing_type: "fill")
    end
  end
end
