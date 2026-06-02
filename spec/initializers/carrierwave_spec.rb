require "rails_helper"

RSpec.describe CarrierWaveInitializer do
  describe ".standard_production_config" do
    it "passes S3-compatible endpoint and path-style settings to fog" do
      stub_application_config(
        "AWS_BUCKET_NAME" => "test-bucket",
        "AWS_ID" => "test-id",
        "AWS_SECRET" => "test-secret",
        "AWS_UPLOAD_REGION" => "ap-southeast-1",
        "AWS_DEFAULT_REGION" => nil,
        "AWS_ENDPOINT_URL" => "https://s3.example.test",
        "AWS_FORCE_PATH_STYLE" => "true",
      )

      described_class.standard_production_config

      expect(CarrierWave::Uploader::Base.fog_credentials).to include(
        endpoint: "https://s3.example.test",
        path_style: true,
      )
    end

    it "does not force S3-compatible options when endpoint and path-style are unset" do
      stub_application_config(
        "AWS_BUCKET_NAME" => "test-bucket",
        "AWS_ID" => "test-id",
        "AWS_SECRET" => "test-secret",
        "AWS_UPLOAD_REGION" => "ap-southeast-1",
        "AWS_DEFAULT_REGION" => nil,
        "AWS_ENDPOINT_URL" => nil,
        "AWS_FORCE_PATH_STYLE" => nil,
      )

      described_class.standard_production_config

      credentials = CarrierWave::Uploader::Base.fog_credentials
      expect(credentials).not_to include(:endpoint)
      expect(credentials).not_to include(:path_style)
    end
  end

  def stub_application_config(values)
    allow(ApplicationConfig).to receive(:[]).and_call_original
    values.each do |key, value|
      allow(ApplicationConfig).to receive(:[]).with(key).and_return(value)
    end
  end
end
