require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe LogoUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:image_svg) { fixture_file_upload("300x100.svg", "image/svg+xml") }
  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }
  let(:image_with_gps) { fixture_file_upload("image_gps_data.jpg", "image/jpeg") }
  let(:image_gif) { fixture_file_upload("high_frame_count.gif", "image/gif") }

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
    expect(uploader.store_dir).to eq("uploads/logos/")
  end

  describe "formats" do
    it "permits a set of extensions" do
      expect(uploader.extension_allowlist).to eq(%w[png jpg jpeg jpe])
    end

    it "permits jpegs" do
      uploader.store!(image_jpg)
      expect(uploader).to be_format("jpeg")
    end

    it "permits pngs" do
      uploader.store!(image_png)
      expect(uploader).to be_format("png")
    end

    it "rejects unsupported formats like SVG" do
      expect { uploader.store!(image_svg) }.to raise_error(CarrierWave::IntegrityError)
    end

    it "rejects unsupported formats like webp" do
      expect { uploader.store!(image_webp) }.to raise_error(CarrierWave::IntegrityError)
    end

    it "rejects unsupported formats like gifs" do
      expect { uploader.store!(image_gif) }.to raise_error(CarrierWave::IntegrityError)
    end
  end

  describe "error handling" do
    it "raises a CarrierWave error which can be parsed if MiniMagick timeout occurs" do
      allow(MiniMagick::Image).to receive(:new).and_raise(Timeout::Error)

      expect { uploader.store!(image_jpg) }.to raise_error(CarrierWave::IntegrityError, /Image processing timed out/)
    end
  end

  describe "exif removal" do
    it "removes EXIF and GPS data on single frame image upload", :aggregate_failures do
      expect(EXIFR::JPEG.new(image_with_gps.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(image_with_gps.path).gps.present?).to be(true)
      uploader.store!(image_with_gps)
      expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
      expect(EXIFR::JPEG.new(uploader.file.path).gps.present?).to be(false)
    end
  end

  describe "resize_image" do
    it "creates versions of the image with different filenames", :aggregate_failures do
      uploader.store!(image_jpg)
      expect(uploader.filename).to match(/original_logo/)
      expect(uploader.resized_logo.file.filename).to match(/resized_logo/)
    end

    it "contains the original file extension when a file is stored" do
      uploader.store!(image_jpg)
      expect(uploader.filename).to match(/\.jpg\z/)
    end

    it "creates versions of the image with different sizes" do
      uploader.store!(image_jpg)
      expect(uploader.resized_logo.size).to be <= uploader.size
    end
  end
end
