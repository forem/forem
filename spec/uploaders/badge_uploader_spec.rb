require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe BadgeUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }
  let(:image_with_gps) { fixture_file_upload("image_gps_data.jpg", "image/jpeg") }

  let(:badge) { create(:badge) }

  # we need a new uploader before each test, and since the uploader is not a model
  # we can recreate it quickly in memory with `let!`
  let!(:uploader) { described_class.new(badge, :badge_image) }

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
      expect(uploader.extension_allowlist).to eq(%w[jpg jpeg gif png])
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

  describe "exif removal" do
    it "removes EXIF and GPS data on upload" do
      expect(EXIFR::JPEG.new(image_with_gps.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(image_with_gps.path).gps.present?).to be(true)
      badge.badge_image = image_with_gps
      badge.save!
      expect(EXIFR::JPEG.new(badge.badge_image.path).exif?).to be(false)
      expect(EXIFR::JPEG.new(badge.badge_image.path).gps.present?).to be(false)
    end
  end
end
