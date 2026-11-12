require "rails_helper"

describe CarrierWaveInitializer do # rubocop:disable RSpec/FilePath, RSpec/SpecFilePathFormat
  around do |example|
    original_config = %i[
      storage
      cache_storage
      fog_directory
      fog_attributes
      fog_public
      fog_credentials
      asset_host
      enable_processing
      move_to_store
    ].index_with { |key| CarrierWave::Uploader::Base.public_send(key) }

    example.run
  ensure
    CarrierWave.configure do |config|
      original_config.each do |key, value|
        config.public_send(:"#{key}=", value)
      end
    end
    CarrierWaveInitializer.reset_descendant_configs! # rubocop:disable RSpec/DescribedClass
  end

  describe ".local_storage_config" do
    it "configures local file storage without errors" do
      expect { described_class.local_storage_config }.not_to raise_error
      expect(CarrierWave::Uploader::Base.storage).to eq(CarrierWave::Storage::File)
      expect(CarrierWave::Uploader::Base.cache_storage).to eq(CarrierWave::Storage::File)
      expect(CarrierWave::Uploader::Base.move_to_store).to be(true)
      expect(CarrierWave::Uploader::Base.fog_public).to be(true)
      expect(CarrierWave::Uploader::Base.fog_attributes).to eq({})
      expect(CarrierWave::Uploader::Base.fog_credentials).to eq({})
    end
  end

  describe ".standard_production_config" do
    it "configures standard production fog storage with local file cache_storage and bounded socket timeouts" do
      expect { described_class.standard_production_config }.not_to raise_error
      expect(CarrierWave::Uploader::Base.storage).to eq(CarrierWave::Storage::Fog)
      expect(CarrierWave::Uploader::Base.cache_storage).to eq(CarrierWave::Storage::File)
      expect(CarrierWave::Uploader::Base.move_to_store).to be(false)
      expect(CarrierWave::Uploader::Base.fog_public).to be(true)
      expect(CarrierWave::Uploader::Base.asset_host).to be_nil
      expect(CarrierWave::Uploader::Base.fog_attributes).to eq(
        { cache_control: "public, max-age=#{365.days.to_i}" },
      )
      expect(CarrierWave::Uploader::Base.fog_credentials[:connection_options]).to eq(
        described_class::FOG_CONNECTION_OPTIONS,
      )
    end
  end

  describe ".forem_cloud_config" do
    it "configures Forem Cloud fog storage with local file cache_storage and bounded socket timeouts" do
      expect { described_class.forem_cloud_config }.not_to raise_error
      expect(CarrierWave::Uploader::Base.storage).to eq(CarrierWave::Storage::Fog)
      expect(CarrierWave::Uploader::Base.cache_storage).to eq(CarrierWave::Storage::File)
      expect(CarrierWave::Uploader::Base.move_to_store).to be(false)
      expect(CarrierWave::Uploader::Base.fog_public).to be(false)
      expect(CarrierWave::Uploader::Base.fog_attributes).to eq({})
      expect(CarrierWave::Uploader::Base.fog_credentials[:use_iam_profile]).to be(true)
      expect(CarrierWave::Uploader::Base.fog_credentials[:connection_options]).to eq(
        described_class::FOG_CONNECTION_OPTIONS,
      )
    end
  end

  describe "mode isolation across uploader subclasses" do
    it "resets cached subclass config ivars when switching from forem_cloud_config to standard_production_config" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("cloud.example.com")
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("cloud-bucket")

      described_class.forem_cloud_config
      expect(ArticleImageUploader.asset_host).to eq("https://cloud.example.com/remoteimages")
      expect(ArticleImageUploader.fog_public).to be(false)
      expect(ArticleImageUploader.move_to_store).to be(false)

      allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return("key-id")
      allow(ApplicationConfig).to receive(:[]).with("AWS_SECRET").and_return("secret")
      allow(ApplicationConfig).to receive(:[]).with("AWS_UPLOAD_REGION").and_return("us-east-1")
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("std-bucket")

      described_class.standard_production_config
      expect(ArticleImageUploader.asset_host).to be_nil
      expect(ArticleImageUploader.fog_public).to be(true)
      expect(ArticleImageUploader.fog_directory).to eq("std-bucket")
      expect(ArticleImageUploader.move_to_store).to be(false)
    end

    it "resets cached subclass config ivars when switching from fog configs back to local_storage_config" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("cloud.example.com")
      allow(ApplicationConfig).to receive(:[]).with("AWS_BUCKET_NAME").and_return("cloud-bucket")

      described_class.forem_cloud_config
      expect(ArticleImageUploader.asset_host).to eq("https://cloud.example.com/remoteimages")
      expect(ArticleImageUploader.storage).to eq(CarrierWave::Storage::Fog)

      described_class.local_storage_config
      expect(ArticleImageUploader.storage).to eq(CarrierWave::Storage::File)
      expect(ArticleImageUploader.cache_storage).to eq(CarrierWave::Storage::File)
      expect(ArticleImageUploader.asset_host).to be_nil
      expect(ArticleImageUploader.move_to_store).to be(true)
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

        allow(described_class).to receive(:standard_production_config)
        described_class.initialize!
        expect(described_class).to have_received(:standard_production_config)
      end

      it "uses forem_cloud_config if FOREM_CONTEXT is forem_cloud" do
        allow(ENV).to receive(:[]).with("FILE_STORAGE_LOCATION").and_return(nil)
        allow(ENV).to receive(:[]).with("FOREM_CONTEXT").and_return("forem_cloud")

        allow(described_class).to receive(:forem_cloud_config)
        described_class.initialize!
        expect(described_class).to have_received(:forem_cloud_config)
      end

      it "uses local_storage_config if FILE_STORAGE_LOCATION is set to file" do
        allow(ENV).to receive(:[]).with("FILE_STORAGE_LOCATION").and_return("file")

        allow(described_class).to receive(:local_storage_config)
        described_class.initialize!
        expect(described_class).to have_received(:local_storage_config)
      end

      it "uses local_storage_config if AWS_ID is blank" do
        allow(ENV).to receive(:[]).with("FILE_STORAGE_LOCATION").and_return(nil)
        allow(ENV).to receive(:[]).with("FOREM_CONTEXT").and_return(nil)
        allow(ApplicationConfig).to receive(:[]).with("AWS_ID").and_return(nil)

        allow(described_class).to receive(:local_storage_config)
        described_class.initialize!
        expect(described_class).to have_received(:local_storage_config)
      end
    end

    context "when not in production environment" do
      it "uses local_storage_config" do
        allow(described_class).to receive(:local_storage_config)
        described_class.initialize!
        expect(described_class).to have_received(:local_storage_config)
      end
    end
  end

  it "does not load MiniMagick at runtime" do
    expect(defined?(MiniMagick)).to be_nil
  end
end
