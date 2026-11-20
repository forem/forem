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

  let!(:uploader) { described_class.new }

  before do
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

    it "raises a CarrierWave error if a timeout occurs during frame counting" do
      allow(ForemNative).to receive(:image_frame_count).and_raise(Timeout::Error)

      expect { uploader.store!(image_jpg) }.to raise_error(CarrierWave::IntegrityError, /Image processing timed out/)
    end

    it "does not spawn any external subprocesses during image upload" do
      allow(Open3).to receive(:popen3).and_call_original
      uploader.store!(image_jpg)
      expect(Open3).not_to have_received(:popen3)
    end

    it "counts frames via ForemNative.image_frame_count and memoizes by path" do
      allow(ForemNative).to receive(:image_frame_count).with(high_frame_count.path).and_call_original

      first_count = uploader.__send__(:frame_count, high_frame_count.path)
      second_count = uploader.__send__(:frame_count, high_frame_count.path)

      expect(first_count).to be > 20
      expect(second_count).to eq(first_count)
      expect(ForemNative).to have_received(:image_frame_count).with(high_frame_count.path).once
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

    it "strips JPEG metadata in place without spawning subprocesses when orientation is normal" do
      allow(Open3).to receive(:popen3).and_call_original
      uploader.store!(image_with_gps)
      expect(Open3).not_to have_received(:popen3)
      expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
      expect(FastImage.size(uploader.file.path)).to eq(FastImage.size(image_with_gps.path))
    end

    it "removes trailing bytes after EOI in-process without spawning subprocesses" do
      Tempfile.create(["trailing", ".jpg"]) do |tmp|
        raw = File.binread(image_with_gps.path)
        File.binwrite(tmp.path, raw + "TrailingMotionPhotoMetadataPayload".b)
        allow(Open3).to receive(:popen3).and_call_original

        uploaded = Rack::Test::UploadedFile.new(tmp.path, "image/jpeg")
        uploader.store!(uploaded)

        expect(Open3).not_to have_received(:popen3)
        expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
        expect(File.binread(uploader.file.path)).not_to include("TrailingMotionPhotoMetadataPayload".b)
      end
    end

    it "auto-orients and strips EXIF in-process when a JPEG has non-default EXIF orientation" do
      Tempfile.create(["rotated", ".jpg"]) do |tmp|
        raw = File.binread(image_jpg.path)
        exif_orientation_6 =
          "\xFF\xE1\x00\x22Exif\x00\x00MM\x00\x2A\x00\x00\x00\x08" \
          "\x00\x01\x01\x12\x00\x03\x00\x00\x00\x01\x00\x06\x00\x00\x00\x00\x00\x00".b
        File.binwrite(tmp.path, "\xFF\xD8".b + exif_orientation_6 + raw.byteslice(2..))
        expect(FastImage.new(tmp.path).orientation).to eq(6)
        allow(Open3).to receive(:popen3).and_call_original

        uploaded = Rack::Test::UploadedFile.new(tmp.path, "image/jpeg")
        uploader.store!(uploaded)

        expect(Open3).not_to have_received(:popen3)
        expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
        expect(FastImage.size(uploader.file.path)).to eq([600, 800])
      end
    end

    it "strips PNG textual metadata chunks in place without spawning subprocesses" do
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

    it "strips EXIF and XMP RIFF chunks from animated WebP uploads without failing or dropping frames" do
      Tempfile.create(["animated", ".webp"]) do |tmp|
        base_webp = File.binread(image_webp.path)
        vp8_chunk = base_webp.byteslice(12..)
        anmf_payload = [0, 0, 0, 0, 0, 0, 31, 3, 0, 87, 2, 0, 10, 0, 0, 0].pack("C*") + vp8_chunk
        anmf_payload << "\x00".b if anmf_payload.bytesize.odd?
        anmf_chunk = "ANMF".b + [anmf_payload.bytesize].pack("V") + anmf_payload

        vp8x = "VP8X".b + [10].pack("V") + [0x0E, 0, 0, 0, 31, 3, 0, 87, 2, 0].pack("C*")
        anim = "ANIM".b + [6].pack("V") + [0, 0, 0, 0, 0, 0].pack("C*")
        exif = "EXIF".b + [8].pack("V") + "GPSSECRT".b
        xmp  = "XMP ".b + [8].pack("V") + "<xmpmeta".b
        body = "WEBP".b + vp8x + anim + anmf_chunk + anmf_chunk + exif + xmp
        animated_webp = "RIFF".b + [body.bytesize].pack("V") + body
        File.binwrite(tmp.path, animated_webp)

        uploaded = Rack::Test::UploadedFile.new(tmp.path, "image/webp")
        uploader.store!(uploaded)

        stored_bytes = File.binread(uploader.file.path)
        expect(stored_bytes).not_to include("GPSSECRT".b)
        expect(stored_bytes).not_to include("<xmpmeta".b)
        info = ForemNative.image_inspect(stored_bytes)
        expect([info[:format], info[:frame_count], info[:width], info[:height]]).to eq(["webp", 2, 800, 600])
      end
    end

    it "does NOT remove EXIF and GPS data if frame count is > FRAME_STRIP_MAX" do
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
