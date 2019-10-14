require "rails_helper"
require "carrierwave/test/matchers"

describe BadgeUploader do
  include CarrierWave::Test::Matchers

  let_it_be(:badge) { create(:badge) }
  let_it_be(:uploader) { described_class.new(badge, :badge_image) }
  let_it_be(:image_jpg) { fixture_file_upload("files/800x600.jpg", "image/jpeg") }
  let_it_be(:image_png) { fixture_file_upload("files/800x600.png", "image/png") }
  let_it_be(:image_webp) { fixture_file_upload("files/800x600.webp", "image/webp") }

  before do
    described_class.include CarrierWave::MiniMagick # needed for processing
    described_class.enable_processing = true
  end

  after do
    described_class.enable_processing = false
    uploader.remove!
  end

  it "stores files in the correct directory" do
    expect(uploader.store_dir).to eq("uploads/badge/badge_image/#{badge.id}")
  end

  describe "formats" do
    it "permits a set of extensions" do
      expect(uploader.extension_whitelist).to eq(%w[jpg jpeg gif png])
    end

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
