require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe SubforemImageUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }
  let(:image_with_gps) { fixture_file_upload("image_gps_data.jpg", "image/jpeg") }

  let!(:uploader) { described_class.new }

  before do
    described_class.enable_processing = true
  end

  after do
    described_class.enable_processing = false
    uploader.remove!
  end

  it "configures store_dir, size_range, and format allowlists", :aggregate_failures do
    expect(uploader.store_dir).to eq("uploads/subforem_images/")
    expect(uploader.size_range).to eq(1..(8.megabytes))
    expect(uploader.extension_allowlist).to eq(%w[png jpg jpeg jpe])
    expect(uploader.content_type_allowlist).to eq(%w[image/png image/jpg image/jpeg])
  end

  it "rejects unsupported formats such as WebP" do
    expect { uploader.store!(image_webp) }.to raise_error(CarrierWave::IntegrityError)
  end

  it "generates :main_logo (128x128), :nav_logo (80x80), and :social_card (1200x630) versions in-process",
     :aggregate_failures do
    allow(Open3).to receive(:popen3).and_call_original
    uploader.set_image_type("logo")

    uploader.store!(image_png)

    expect(Open3).not_to have_received(:popen3)
    expect(uploader.file.filename).to match(/\Alogo_[A-Za-z0-9]{20}\.png\z/)
    expect(uploader.url).to start_with("https://test.host/")
    expect(uploader.main_logo).to have_dimensions(128, 128)
    expect(uploader.main_logo.file.filename).to match(/\Amain_logo_[A-Za-z0-9]{20}\.png\z/)
    expect(uploader.nav_logo).to have_dimensions(80, 80)
    expect(uploader.nav_logo.file.filename).to match(/\Anav_logo_[A-Za-z0-9]{20}\.png\z/)
    expect(uploader.social_card).to have_dimensions(1200, 630)
    expect(uploader.social_card.file.filename).to match(/\Asocial_card_[A-Za-z0-9]{20}\.png\z/)
  end

  it "strips EXIF and GPS metadata from JPEG uploads and generates all versions", :aggregate_failures do
    uploader.store!(image_with_gps)

    expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
    expect(uploader.main_logo).to have_dimensions(128, 128)
    expect(uploader.nav_logo).to have_dimensions(80, 80)
    expect(uploader.social_card).to have_dimensions(1200, 630)
  end
end
