require "rails_helper"
require "carrierwave/test/matchers"

describe ArticleImageUploader do
  include CarrierWave::Test::Matchers

  let(:uploader) { described_class.new }
  let(:image_jpg) { fixture_file_upload("files/800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("files/800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("files/800x600.webp", "image/webp") }

  before do
    described_class.include CarrierWave::MiniMagick # needed for processing
    described_class.enable_processing = true
  end

  after do
    described_class.enable_processing = false
    uploader.remove!
  end

  it "stores files in the correct directory" do
    expect(uploader.store_dir).to eq("i/")
  end

  describe "filename" do
    it "defaults to nil" do
      expect(uploader.filename).to be_nil
    end

    it "contains the original file extension when a file is stored" do
      uploader.store!(image_jpg)
      expect(uploader.filename).to match(/\.jpg/)
    end
  end

  describe "formats" do
    it "permits jpegs" do
      uploader.store!(image_jpg)
      expect(uploader).to be_format("jpeg")
    end

    it "permits pngs" do
      uploader.store!(image_png)
      expect(uploader).to be_format("png")
    end

    it "rejects unsupported formats like webp" do
      expect { uploader.store!(image_webp) }.to raise_error(CarrierWave::IntegrityError)
    end
  end
end
