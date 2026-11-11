require "rails_helper"
require "carrierwave/test/matchers"

describe LogoSvgUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:image_svg) { fixture_file_upload("300x100.svg", "image/svg+xml") }
  let(:gradient_svg) { fixture_file_upload("unicorn.svg", "image/svg+xml") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }

  let!(:uploader) { described_class.new }

  before do
    described_class.enable_processing = true
  end

  after do
    described_class.enable_processing = false
    uploader.remove!
  end

  it "stores files in the logos directory with a .png filename", :aggregate_failures do
    expect(uploader.store_dir).to eq("uploads/logos/")
    expect(uploader.extension_allowlist).to eq(%w[svg png])
    expect(uploader.content_type_allowlist).to eq(%w[image/svg+xml image/png])
    expect(uploader.filename).to match(/\Aoriginal_logo_[A-Za-z0-9]{20}\.png\z/)
  end

  describe "SVG and PNG conversion" do
    it "converts an SVG with <text> elements into a PNG and resizes :resized_logo to <= 80px tall",
       :aggregate_failures do
      allow(Open3).to receive(:popen3).and_call_original

      uploader.store!(image_svg)

      expect(Open3).not_to have_received(:popen3)
      expect(uploader).to be_format("png")
      expect(uploader).to have_dimensions(300, 100)
      expect(uploader.resized_logo).to be_format("png")
      expect(uploader.resized_logo).to be_no_taller_than(80)
      expect(uploader.resized_logo).to have_dimensions(240, 80)
      expect(uploader.resized_logo.file.filename).to match(/\Aresized_logo_[A-Za-z0-9]{20}\.png\z/)
    end

    it "converts a multi-path SVG with linear gradients and preserves alpha transparency", :aggregate_failures do
      uploader.store!(gradient_svg)

      expect(uploader).to be_format("png")
      expect(uploader.resized_logo).to be_format("png")
      expect(uploader.resized_logo).to be_no_taller_than(80)
      # Color type byte at offset 25 of PNG IHDR: 6 = RGBA (truecolor with alpha)
      expect(File.binread(uploader.file.path).getbyte(25)).to eq(6)
    end

    it "processes PNG inputs and downscales :resized_logo proportionally", :aggregate_failures do
      uploader.store!(image_png)

      expect(uploader).to be_format("png")
      expect(uploader).to have_dimensions(800, 600)
      expect(uploader.resized_logo).to have_dimensions(107, 80)
    end

    it "rejects disallowed formats such as JPEG" do
      expect { uploader.store!(image_jpg) }.to raise_error(CarrierWave::IntegrityError)
    end

    it "raises CarrierWave::ProcessingError when ForemNative.image_convert_to_png fails" do
      allow(ForemNative).to receive(:image_convert_to_png).and_raise(ArgumentError, "malformed SVG")

      expect { uploader.store!(image_svg) }.to raise_error(CarrierWave::ProcessingError)
    end
  end
end
