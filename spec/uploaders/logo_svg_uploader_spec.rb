require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe LogoSvgUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:image_svg) { fixture_file_upload("300x100.svg", "image/svg+xml") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }

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

  describe "error handling" do
    it "raises a CarrierWave error which can be parsed if MiniMagick timeout occurs" do
      allow(MiniMagick::Image).to receive(:new).and_raise(Timeout::Error)

      expect { uploader.store!(image_svg) }.to raise_error(CarrierWave::IntegrityError, /Image processing timed out/)
    end
  end

  describe "processed images" do
    it "creates versions of the image with different filenames", :aggregate_failures do
      uploader.store!(image_svg)
      expect(uploader.filename).to match(/original_logo/)
      expect(uploader.resized_logo.file.filename).to match(/resized_logo/)
    end

    it "stores the processed logo's with a png file extension" do
      uploader.store!(image_svg)
      expect(uploader.filename).to match(/\.png\z/)
      expect(uploader.resized_logo.file.filename).to match(/\.png\z/)
    end

    it "stores the processed logo as a png content type" do
      uploader.store!(image_svg)
      expect(uploader.content_type).to match(/png/)
      expect(uploader.resized_logo.file.content_type).to match(/png/)
    end
  end
end
