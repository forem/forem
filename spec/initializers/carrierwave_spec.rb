require "rails_helper"

describe CarrierWaveInitializer do
  # Store and restore configuration to avoid test leakage
  before(:all) do
    @original_config = {}
    %i[
      storage
      fog_directory
      fog_attributes
      fog_credentials
      asset_host
      enable_processing
    ].each do |key|
      @original_config[key] = CarrierWave::Uploader::Base.send(key) if CarrierWave::Uploader::Base.respond_to?(key)
    end
  end

  after(:all) do
    CarrierWave.configure do |config|
      @original_config.each do |key, value|
        config.send("#{key}=", value)
      end
    end
  end

  describe ".local_storage_config" do
    it "configures local file storage without errors" do
      expect { described_class.local_storage_config }.not_to raise_error
      expect(CarrierWave::Uploader::Base.storage).to eq(CarrierWave::Storage::File)
    end
  end

  describe ".standard_production_config" do
    it "configures standard production fog storage without errors" do
      expect { described_class.standard_production_config }.not_to raise_error
      expect(CarrierWave::Uploader::Base.storage).to eq(CarrierWave::Storage::Fog)
    end
  end

  describe ".forem_cloud_config" do
    it "configures Forem Cloud fog storage without errors" do
      expect { described_class.forem_cloud_config }.not_to raise_error
      expect(CarrierWave::Uploader::Base.storage).to eq(CarrierWave::Storage::Fog)
    end
  end

  describe ".initialize!" do
    context "when in production environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end

      it "uses standard_production_config if AWS_ID is present" do
        allow(ENV).to receive(:[]).with("FILE_STORAGE_LOCATION").and_return(nil)
        allow(ENV).to receive(:[]).with("FOREM_CONTEXT").and_return(nil)
        allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("mock-aws-id")

        # Mock other config calls to avoid key lookup errors
        allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("mock-bucket")
        allow(ApplicationConfig).to receive(:[]).with("AWS_SECRET").and_return("mock-secret")
        allow(ApplicationConfig).to receive(:[]).with("AWS_UPLOAD_REGION").and_return("us-east-1")
        allow(ApplicationConfig).to receive(:[]).with("AWS_DEFAULT_REGION").and_return("us-east-1")

        expect(described_class).to receive(:standard_production_config)
        described_class.initialize!
      end

      it "uses forem_cloud_config if FOREM_CONTEXT is forem_cloud" do
        allow(ENV).to receive(:[]).with("FILE_STORAGE_LOCATION").and_return(nil)
        allow(ENV).to receive(:[]).with("FOREM_CONTEXT").and_return("forem_cloud")

        expect(described_class).to receive(:forem_cloud_config)
        described_class.initialize!
      end

      it "uses local_storage_config if FILE_STORAGE_LOCATION is set to file" do
        allow(ENV).to receive(:[]).with("FILE_STORAGE_LOCATION").and_return("file")

        expect(described_class).to receive(:local_storage_config)
        described_class.initialize!
      end

      it "uses local_storage_config if AWS_ID is blank" do
        allow(ENV).to receive(:[]).with("FILE_STORAGE_LOCATION").and_return(nil)
        allow(ENV).to receive(:[]).with("FOREM_CONTEXT").and_return(nil)
        allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return(nil)

        expect(described_class).to receive(:local_storage_config)
        described_class.initialize!
      end
    end

    context "when not in production environment" do
      it "uses local_storage_config" do
        expect(described_class).to receive(:local_storage_config)
        described_class.initialize!
      end
    end
  end
end
