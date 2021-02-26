require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe ProfileImageUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:mounted_as) { :profile_image }
  let(:image_jpg) { fixture_file_upload("files/800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("files/800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("files/800x600.webp", "image/webp") }
  let(:image_with_gps) { fixture_file_upload("files/image_gps_data.jpg", "image/jpeg") }

  let(:user) { create(:user) }

  # we need a new uploader before each test, and since the uploader is not a model
  # we can recreate it quickly in memory with `let!`
  let!(:uploader) { described_class.new(user, mounted_as) }

  before do
    described_class.include CarrierWave::MiniMagick # needed for processing
    described_class.enable_processing = true
  end

  after do
    described_class.enable_processing = false
    uploader.remove!
  end

  it "stores files in the correct directory" do
    expect(uploader.store_dir).to eq("uploads/user/profile_image/#{user.id}")
  end

  describe "filename" do
    it "defaults to nil" do
      expect(uploader.filename).to be_nil
    end

    it "contains a secure token" do
      uploader.store!(image_jpg)
      token = user.instance_variable_get(:"@#{mounted_as}_secure_token")
      expect(uploader.filename).to include(token)
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

  describe "exif removal" do
    it "removes EXIF and GPS data on upload" do
      expect(EXIFR::JPEG.new(image_with_gps.path).exif?).to be(true)
      expect(EXIFR::JPEG.new(image_with_gps.path).gps.present?).to be(true)
      user.profile_image = image_with_gps
      user.save!
      expect(EXIFR::JPEG.new(user.profile_image.path).exif?).to be(false)
      expect(EXIFR::JPEG.new(user.profile_image.path).gps.present?).to be(false)
    end
  end
end
