require "rails_helper"
require "carrierwave/test/matchers"

RSpec.describe NavigationLinkImageUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:navigation_link) { create(:navigation_link) }
  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }
  let(:image_svg) { fixture_file_upload("300x100.svg", "image/svg+xml") }
  
  let!(:uploader) { described_class.new(navigation_link, :image) }

  before do
    described_class.include CarrierWave::MiniMagick
    # Note: We keep processing disabled to avoid needing ImageMagick in CI
    described_class.enable_processing = false
  end

  after do
    uploader.remove!
  end

  it "stores files in the correct directory" do
    expect(uploader.store_dir).to eq("uploads/navigation_link_images/")
  end

  describe "formats" do
    it "permits a set of extensions" do
      expect(uploader.extension_allowlist).to eq(%w[png jpg jpeg jpe])
    end

    it "permits jpegs" do
      uploader.store!(image_jpg)
      expect(uploader.file.extension).to eq("jpg")
    end

    it "permits pngs" do
      uploader.store!(image_png)
      expect(uploader.file.extension).to eq("png")
    end

    it "rejects unsupported formats like webp" do
      expect { uploader.store!(image_webp) }.to raise_error(CarrierWave::IntegrityError)
    end

    it "rejects unsupported formats like SVG" do
      expect { uploader.store!(image_svg) }.to raise_error(CarrierWave::IntegrityError)
    end
  end

  describe "filename" do
    it "uses a secure token" do
      uploader.store!(image_png)
      expect(uploader.filename).to match(/\A[a-f0-9\-]+\.png\z/)
    end

    it "contains the original file extension when a file is stored" do
      uploader.store!(image_jpg)
      expect(uploader.filename).to match(/\.jpg\z/)
    end
  end

  describe "file size limits" do
    it "has a maximum file size of 5MB" do
      expect(uploader.size_range).to eq(1..5.megabytes)
    end
  end

  describe "content type allowlist" do
    it "only allows specific image types" do
      expect(uploader.content_type_allowlist).to eq(%w[image/png image/jpg image/jpeg])
    end
  end
end

