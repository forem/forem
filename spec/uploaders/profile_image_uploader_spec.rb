require "rails_helper"
require "carrierwave/test/matchers"

describe ProfileImageUploader do
  include CarrierWave::Test::Matchers

  let_it_be(:mounted_as) { :profile_image }
  let_it_be(:user) { create(:user) }
  let_it_be(:uploader) { described_class.new(user, mounted_as) }
  let_it_be(:image_jpg) { fixture_file_upload("files/800x600.jpg", "image/jpeg") }
  let_it_be(:image_png) { fixture_file_upload("files/800x600.png", "image/png") }
  let_it_be(:image_webp) { fixture_file_upload("files/800x600.webp", "image/webp") }

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
      expect(uploader.extension_whitelist).to eq(%w[jpg jpeg jpe gif png ico bmp dng])
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
end
