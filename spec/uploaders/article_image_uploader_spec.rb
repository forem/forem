require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe ArticleImageUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }
  let(:image_pdf) { fixture_file_upload("800x600.pdf", "application/pdf") }
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
      expect(uploader.extension_allowlist).to eq(%w[jpg jpeg jpe gif png ico bmp dng webp])
    end

    it "permits jpegs" do
      uploader.store!(image_jpg)
      expect(uploader).to be_format("jpeg")
    end

    it "permits pngs" do
      uploader.store!(image_png)
      expect(uploader).to be_format("png")
    end

    it "permits webp" do
      uploader.store!(image_webp)
      expect(uploader).to be_format("webp")
    end

    it "rejects unsupported formats like pdf" do
      expect { uploader.store!(image_pdf) }.to raise_error(CarrierWave::IntegrityError)
    end
  end

  describe "frame validation" do
    it "raises an error if frame count is > FRAME_MAX" do
      stub_const("BaseUploader::FRAME_MAX", 20)

      expect { uploader.store!(high_frame_count) }.to raise_error(CarrierWave::IntegrityError, /too many frames/)
    end

    it "raises a CarrierWave error which can be parsed if MiniMagick timeout occurs" do
      allow(MiniMagick::Image).to receive(:new).and_raise(Timeout::Error)

      expect { uploader.store!(image_jpg) }.to raise_error(CarrierWave::IntegrityError, /Image processing timed out/)
    end

    it "does not spawn ImageMagick identify for non-animated images" do
      allow(Open3).to receive(:popen3).and_call_original
      uploader.store!(image_jpg)
      expect(Open3).not_to have_received(:popen3)
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

    it "strips JPEG metadata in place without spawning MiniMagick subprocesses when orientation is normal" do
      allow(Open3).to receive(:popen3).and_call_original
      uploader.store!(image_with_gps)
      expect(Open3).not_to have_received(:popen3)
      expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
      expect(FastImage.size(uploader.file.path)).to eq(FastImage.size(image_with_gps.path))
    end

    it "auto-orients and strips EXIF via MiniMagick when a JPEG has non-default EXIF orientation" do
      Tempfile.create(["rotated", ".jpg"]) do |tmp|
        raw = File.binread(image_jpg.path)
        exif_orientation_6 =
          "\xFF\xE1\x00\x22Exif\x00\x00MM\x00\x2A\x00\x00\x00\x08" \
          "\x00\x01\x01\x12\x00\x03\x00\x00\x00\x01\x00\x06\x00\x00\x00\x00\x00\x00".b
        File.binwrite(tmp.path, "\xFF\xD8".b + exif_orientation_6 + raw.byteslice(2..))
        expect(FastImage.new(tmp.path).orientation).to eq(6)

        uploaded = Rack::Test::UploadedFile.new(tmp.path, "image/jpeg")
        uploader.store!(uploaded)

        expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
        expect(FastImage.size(uploader.file.path)).to eq([600, 800])
      end
    end

    it "strips PNG textual metadata chunks in place without spawning MiniMagick subprocesses" do
      Tempfile.create(["metadata", ".png"]) do |tmp|
        raw = File.binread(image_png.path)
        iend_offset = raw.rindex("IEND".b) - 4
        payload = "Comment\x00SecretMetadataPayload".b
        crc = [Zlib.crc32("tEXt".b + payload)].pack("N")
        text_chunk = [payload.bytesize].pack("N") + "tEXt".b + payload + crc
        File.binwrite(tmp.path, raw.byteslice(0, iend_offset) + text_chunk + raw.byteslice(iend_offset..))

        expect(File.binread(tmp.path)).to include("SecretMetadataPayload".b)
        allow(Open3).to receive(:popen3).and_call_original

        uploaded = Rack::Test::UploadedFile.new(tmp.path, "image/png")
        uploader.store!(uploaded)

        expect(Open3).not_to have_received(:popen3)
        stored_bytes = File.binread(uploader.file.path)
        expect(stored_bytes).not_to include("SecretMetadataPayload".b)
        expect(FastImage.size(uploader.file.path)).to eq([800, 600])
      end
    end

    it "does NOT remove EXIF and GPS data or invoke MiniMagick if frame count is > FRAME_STRIP_MAX" do
      stub_const("BaseUploader::FRAME_STRIP_MAX", 0)
      expect(EXIFR::JPEG.new(image_with_gps.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(image_with_gps.path).gps.present?).to be(true)
      allow(Open3).to receive(:popen3).and_call_original
      uploader.store!(image_with_gps)
      expect(Open3).not_to have_received(:popen3)
      expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(uploader.file.path).gps.present?).to be(true)
    end
  end
end
