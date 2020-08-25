require "rails_helper"

RSpec.describe Images::Optimizer, type: :service do
  include CloudinaryHelper

  let(:image_url) { "https://i.imgur.com/fKYKgo4.png" }

  describe "#call" do
    before do
      allow(described_class).to receive(:cloudinary)
      allow(described_class).to receive(:imgproxy)
    end

    it "calls cloudinary on default" do
      described_class.call(image_url, service: nil)
      expect(described_class).to have_received(:cloudinary)
    end

    it "calls cloudinary if imgproxy's key and endpoint is missing" do
      described_class.call(image_url, service: :imgproxy)
      expect(described_class).to have_received(:cloudinary)
    end

    it "calls imgproxy if imgproxy's key and endpoint is provided" do
      Imgproxy.config.key = "secret"
      Imgproxy.config.endpoint = "https://dev.to"
      described_class.call(image_url, service: :imgproxy)
      expect(described_class).to have_received(:imgproxy)
      Imgproxy.config.key = nil
      Imgproxy.config.endpoint = nil
    end
  end

  describe "#cloudinary" do
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
    before do
      Imgproxy.config.key = "secret"
      Imgproxy.config.endpoint = "https://dev.to"
    end

    after do
      Imgproxy.config.key = nil
      Imgproxy.config.endpoint = nil
    end

    it "works" do
      imgproxy_url = described_class.imgproxy(image_url, service: :imgproxy, width: 500, height: 500)
      expect(imgproxy_url).to match(%r{/unsafe/s:500:500/aHR0cHM6Ly9pLmlt/Z3VyLmNvbS9mS1lL/Z280LnBuZw})
    end
  end
end
