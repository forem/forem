require "rails_helper"
require "carrierwave/test/matchers"
require "exifr/jpeg"

describe ProfileImageUploader, type: :uploader do
  include CarrierWave::Test::Matchers

  let(:mounted_as) { :profile_image }
  let(:image_jpg) { fixture_file_upload("800x600.jpg", "image/jpeg") }
  let(:image_png) { fixture_file_upload("800x600.png", "image/png") }
  let(:image_webp) { fixture_file_upload("800x600.webp", "image/webp") }
  let(:image_pdf) { fixture_file_upload("800x600.pdf", "application/pdf") }
  let(:image_with_gps) { fixture_file_upload("image_gps_data.jpg", "image/jpeg") }

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

    it "permits webps" do
      uploader.store!(image_webp)
      expect(uploader).to be_format("webp")
    end

    it "rejects unsupported formats like pdf" do
      expect { uploader.store!(image_pdf) }.to raise_error(CarrierWave::IntegrityError)
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

  describe "fog storage behavior" do
    around do |example|
      user # ensure user is created before switching ProfileImageUploader to fog storage

      original_storage = described_class.storage
      original_cache_storage = described_class.cache_storage
      original_fog_credentials = described_class.fog_credentials
      original_fog_directory = described_class.fog_directory

      Fog.mock!
      Fog::Mock.reset
      credentials = {
        provider: "AWS",
        aws_access_key_id: "test-key",
        aws_secret_access_key: "test-secret",
        region: "us-east-1"
      }
      Fog::Storage.new(credentials).directories.create(key: "test-bucket")

      described_class.storage = :fog
      described_class.cache_storage = :file
      described_class.fog_credentials = credentials
      described_class.fog_directory = "test-bucket"

      example.run
    ensure
      described_class.storage = original_storage
      described_class.cache_storage = original_cache_storage
      described_class.fog_credentials = original_fog_credentials
      described_class.fog_directory = original_fog_directory
      Fog.unmock!
    end

    it "does not issue S3 HEAD requests when validating a model or checking #present? / #blank?" do
      user.update_column(:profile_image, "existing_avatar.jpg")
      reloaded_user = User.find(user.id)

      fog_file = reloaded_user.profile_image.file
      expect(fog_file).to be_a(CarrierWave::Storage::Fog::File)
      allow(fog_file).to receive(:exists?)

      expect(reloaded_user.profile_image.blank?).to be(false)
      expect(reloaded_user.profile_image.present?).to be(true)
      expect(reloaded_user.profile_image?).to be(true)
      expect(reloaded_user.valid?).to be(true)
      expect(fog_file).not_to have_received(:exists?)
    end

    it "returns blank? true when no file is mounted on a fog-backed uploader" do
      user.update_column(:profile_image, nil)
      reloaded_user = User.find(user.id)

      expect(reloaded_user.profile_image.blank?).to be(true)
      expect(reloaded_user.profile_image.present?).to be(false)
    end

    it "caches locally and uploads directly to final S3 store path without temporary S3 cache objects" do
      fresh_uploader = described_class.new(user, mounted_as)
      expect(fresh_uploader.__send__(:cache_storage)).to be_a(CarrierWave::Storage::File)

      fresh_uploader.store!(image_jpg)

      connection = Fog::Storage.new(described_class.fog_credentials)
      bucket_keys = connection.directories.get("test-bucket").files.map(&:key)

      expect(bucket_keys.length).to eq(1)
      expect(bucket_keys.first).to start_with("uploads/user/profile_image/#{user.id}/")
      expect(bucket_keys).to all(satisfy { |k| k.exclude?("uploads/tmp/") })
    end
  end
end
