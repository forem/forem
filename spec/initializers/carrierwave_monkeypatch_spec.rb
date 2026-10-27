# rubocop:disable RSpec/FilePath
require "rails_helper"

describe CarrierWave::Storage::Fog::File do
  it "replaces ApplicationConfig APP_DOMAIN with Settings::General.app_domain" do
    CarrierWave::Uploader::Base.fog_credentials = {
      provider: "AWS", aws_access_key_id: "foo", aws_secret_access_key: "bar"
    }
    allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("s3.amazonaws.com")
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
    file_url = described_class.new(
      CarrierWave::Uploader::Base, nil, "/a/path"
    ).url

    expect(file_url).to include("forem.com")
  end

  describe "#blank?" do
    it "returns false when path is present without making a remote HEAD request" do
      fog_file = described_class.new(CarrierWave::Uploader::Base, nil, "uploads/user/profile_image/1/avatar.jpg")
      allow(fog_file).to receive(:exists?)

      expect(fog_file.blank?).to be(false)
      expect(fog_file.present?).to be(true)
      expect(fog_file).not_to have_received(:exists?)
    end

    it "returns true when path is blank without making a remote HEAD request" do
      fog_file = described_class.new(CarrierWave::Uploader::Base, nil, "")
      allow(fog_file).to receive(:exists?)

      expect(fog_file.blank?).to be(true)
      expect(fog_file.present?).to be(false)
      expect(fog_file).not_to have_received(:exists?)
    end
  end

  describe "#copy_to" do
    before do
      Fog.mock!
      Fog::Mock.reset
    end

    after do
      Fog.unmock!
    end

    it "copies the S3 object via connection.copy_object without issuing a redundant HEAD request on the target" do
      credentials = {
        provider: "AWS",
        aws_access_key_id: "test-key",
        aws_secret_access_key: "test-secret",
        region: "us-east-1"
      }
      uploader = instance_double(
        CarrierWave::Uploader::Base,
        fog_credentials: credentials,
        fog_directory: "test-bucket",
        fog_public: true,
        fog_attributes: { cache_control: "public, max-age=31536000" },
      )
      storage = CarrierWave::Storage::Fog.new(uploader)
      storage.connection.directories.create(key: "test-bucket")
      storage.connection.put_object("test-bucket", "uploads/tmp/source.jpg", "image-bytes")

      source_file = described_class.new(uploader, storage, "uploads/tmp/source.jpg")
      source_file.content_type = "image/jpeg"

      allow(storage.connection).to receive(:copy_object).and_call_original
      allow(storage.connection).to receive(:head_object).and_call_original

      copied_file = source_file.copy_to("uploads/final/dest.jpg")

      expect(copied_file).to be_a(described_class)
      expect(copied_file.path).to eq("uploads/final/dest.jpg")
      expect(storage.connection).to have_received(:copy_object).with(
        "test-bucket",
        "uploads/tmp/source.jpg",
        "test-bucket",
        "uploads/final/dest.jpg",
        hash_including("x-amz-acl" => "public-read", "Content-Type" => "image/jpeg"),
      ).once
      expect(storage.connection).not_to have_received(:head_object)
      expect(storage.connection.get_object("test-bucket", "uploads/final/dest.jpg").body).to eq("image-bytes")
    end
  end
end
# rubocop:enable RSpec/FilePath
