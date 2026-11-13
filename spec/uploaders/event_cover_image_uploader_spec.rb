require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe EventCoverImageUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:event) { build_stubbed(:event) }
  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_with_gps) { fixture_file_upload("image_gps_data.jpg", "image/jpeg") }

  let!(:uploader) { described_class.new(event, :cover_image) }

  before do
    described_class.enable_processing = true
  end

  after do
    described_class.enable_processing = false
    uploader.remove!
  end

  it "configures store_dir, size_range, and a UUID filename per model", :aggregate_failures do
    expect(uploader.store_dir).to eq("uploads/events/cover_image/#{event.id}")
    expect(uploader.size_range).to eq(1..(25.megabytes))
    expect(uploader.filename).to be_nil

    uploader.store!(image_jpg)
    expect(uploader.filename).to match(/\A[0-9a-f-]{36}\.jpg\z/)
  end

  it "creates a 1200x630 center-cropped :social version without spawning subprocesses", :aggregate_failures do
    allow(Open3).to receive(:popen3).and_call_original

    uploader.store!(image_png)

    expect(Open3).not_to have_received(:popen3)
    expect(uploader).to be_format("png")
    expect(uploader).to have_dimensions(800, 600)
    expect(uploader.social).to be_format("png")
    expect(uploader.social).to have_dimensions(1200, 630)
  end

  it "strips EXIF and GPS metadata from uploaded cover images", :aggregate_failures do
    expect(EXIFR::JPEG.new(image_with_gps.path).exif?).to be(true)

    uploader.store!(image_with_gps)

    expect(EXIFR::JPEG.new(uploader.file.path).exif?).to be(false)
    expect(EXIFR::JPEG.new(uploader.social.file.path).exif?).to be(false)
    expect(uploader.social).to have_dimensions(1200, 630)
  end
end
