require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe ArticleImageUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }
  let(:image_with_gps) { fixture_file_upload("image_gps_data.jpg", "image/jpeg") }
  let(:high_frame_count) { fixture_file_upload("high_frame_count.gif", "image/gif") }

  # we need a new uploader before each test, and since the uploader is not a model
  # we can recreate it quickly in memory with `let!`
  let!(:uploader) { described_class.new }

  before do
    described_class.include CarrierWave::MiniMagick # needed for processing
    described_class.enable_processing = true
  end

  after do
    described_class.enable_processing = false
    uploader.remove!
  end

  it "stores files in the correct directory" do
    expect(uploader.store_dir).to eq("uploads/articles/")
  end

  describe "filename" do
    it "defaults to nil" do
      expect(uploader.filename).to be_nil
    end

    it "contains the original file extension when a file is stored" do
      uploader.store!(image_jpg)
      expect(uploader.filename).to match(/\.jpg\z/)
    end
  end

  describe "formats" do
    it "permits a set of extensions" do
      expect(uploader.extension_allowlist).to eq(%w[jpg jpeg jpe gif png ico bmp dng])
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

  describe "frame validation" do
    it "raises an error if frame count is > FRAME_MAX" do
      stub_const("BaseUploader::FRAME_MAX", 20)

      expect { uploader.store!(high_frame_count) }.to raise_error(CarrierWave::IntegrityError, /too many frames/)
    end

    it "raises a CarrierWave error which can be parsed if MiniMagick timeout occurs" do
      allow(MiniMagick::Image).to receive(:new).and_raise(TimeoutError)

      expect { uploader.store!(image_jpg) }.to raise_error(CarrierWave::IntegrityError, /Image processing timed out/)
    end
  end

  describe "exif removal" do
    it "removes EXIF and GPS data on single frame image upload" do
      expect(EXIFR::JPEG.new(image_with_gps.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(image_with_gps.path).gps.present?).to be(true)
      uploader.store!(image_with_gps)
      expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
      expect(EXIFR::JPEG.new(uploader.file.path).gps.present?).to be(false)
    end

    it "does NOT remove EXIF and GPS data if frame count is > FRAME_STRIP_MAX" do
      stub_const("BaseUploader::FRAME_STRIP_MAX", 0)
      expect(EXIFR::JPEG.new(image_with_gps.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(image_with_gps.path).gps.present?).to be(true)
      uploader.store!(image_with_gps)
      expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(uploader.file.path).gps.present?).to be(true)
    end
  end
end
