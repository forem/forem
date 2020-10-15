require "rails_helper"

RSpec.describe Images::Optimizer, type: :service do
  include CloudinaryHelper

  let(:image_url) { "https://i.imgur.com/fKYKgo4.png" }

  def stub_imgproxy
    imgproxy_config_stub = Imgproxy::Config.new.tap do |config|
      config.key = "secret"
      config.salt = "secret"
      config.base64_encode_urls = true
    end
    allow(Imgproxy).to receive(:config).and_return(imgproxy_config_stub)
  end

  describe "#call" do
    before do
      allow(described_class).to receive(:cloudinary)
      allow(described_class).to receive(:imgproxy)
    end

    it "calls cloudinary if imgproxy is not enabled" do
      allow(described_class).to receive(:imgproxy_enabled?).and_return(false)
      described_class.call(image_url)
      expect(described_class).to have_received(:cloudinary)
    end

    it "calls cloudinary if imgproxy's key and salt is missing" do
      allow(Imgproxy).to receive(:config).and_return(Imgproxy::Config.new)
      described_class.call(image_url, service: :imgproxy)
      expect(described_class).to have_received(:cloudinary)
    end

    it "calls imgproxy if imgproxy's key and salt is provided" do
      stub_imgproxy
      described_class.call(image_url, service: :imgproxy)
      expect(described_class).to have_received(:imgproxy)
    end
  end

  describe "#cloudinary" do
    it "performs exactly like cl_image_path" do
      allow(described_class).to receive(:imgproxy_enabled?).and_return(false)
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
      allow(described_class).to receive(:imgproxy_enabled?).and_return(false)
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
      stub_imgproxy
      imgproxy_url = described_class.imgproxy(image_url, service: :imgproxy, width: 500, height: 500)
      expect(imgproxy_url).to match(%r{/s:500:500/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end
  end
end
