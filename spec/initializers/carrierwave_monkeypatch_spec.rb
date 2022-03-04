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
end
# rubocop:enable RSpec/FilePath
