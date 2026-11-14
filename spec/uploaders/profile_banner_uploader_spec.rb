require "rails_helper"
require "carrierwave/test/matchers"

describe ProfileBannerUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:mounted_as) { :profile_banner_image }
  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_pdf) { fixture_file_upload("800x600.pdf", "application/pdf") }
  let(:image_svg) { fixture_file_upload("300x100.svg", "image/svg+xml") }

  let(:user) { create(:user) }

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
    expect(uploader.store_dir).to eq("uploads/user/profile_banner_image/#{user.id}")
  end

  it "limits files to 8 megabytes" do
    expect(uploader.size_range).to eq(1..8.megabytes)
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
      uploader.store!(image_png)
      expect(uploader.filename).to match(/\.png\z/)
    end
  end

  describe "formats" do
    it "permits a set of image extensions" do
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

    it "rejects pdfs" do
      expect { uploader.store!(image_pdf) }.to raise_error(CarrierWave::IntegrityError)
    end

    it "rejects svgs" do
      expect { uploader.store!(image_svg) }.to raise_error(CarrierWave::IntegrityError)
    end
  end
end
