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
      move_to_store
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
      expect(CarrierWave::Uploader::Base.move_to_store).to be(true)
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

  describe MiniMagickShellTimeoutGuard do
    describe ".effective_timeout" do
      it "returns MiniMagick.timeout when not inside a Rack::Timeout request" do
        allow(RackTimeoutThreadTracker).to receive(:remaining_timeout).and_return(nil)
        expect(described_class.effective_timeout).to eq(MiniMagick.timeout)
      end

      it "caps the timeout to remaining request budget minus headroom when budget is tight" do
        allow(RackTimeoutThreadTracker).to receive(:remaining_timeout).and_return(2.5)
        expect(described_class.effective_timeout).to eq(1.5)
      end

      it "keeps MiniMagick.timeout when the remaining request budget is larger" do
        allow(RackTimeoutThreadTracker).to receive(:remaining_timeout).and_return(25.0)
        expect(described_class.effective_timeout).to eq(MiniMagick.timeout.to_f)
      end
    end

    describe "#execute_open3" do
      let(:shell) { MiniMagick::Shell.new }

      it "raises Timeout::Error before spawning a subprocess when remaining budget is exhausted" do
        allow(described_class).to receive(:effective_timeout).and_return(0.0)
        allow(Open3).to receive(:popen3)

        expect do
          shell.__send__(:execute_open3, ["identify", "-version"])
        end.to raise_error(Timeout::Error, /insufficient request budget/)
        expect(Open3).not_to have_received(:popen3)
      end

      it "terminates the child process in ensure if an asynchronous exception interrupts execution" do
        in_r, in_w = IO.pipe
        out_r, out_w = IO.pipe
        err_r, err_w = IO.pipe
        out_w.close
        err_w.close

        wait_thr = instance_double(Process::Waiter, pid: 99_999, alive?: true)
        allow(wait_thr).to receive(:join).and_raise(Rack::Timeout::RequestTimeoutException.new({}))
        allow(Open3).to receive(:popen3).and_yield(in_w, out_r, err_r, wait_thr)
        allow(Process).to receive(:kill)
        allow(Process).to receive(:waitpid)

        expect do
          shell.__send__(:execute_open3, ["mogrify", "test.jpg"])
        end.to raise_error(Rack::Timeout::RequestTimeoutException)

        expect(Process).to have_received(:kill).with("TERM", 99_999)
        expect(Process).to have_received(:waitpid).with(99_999)
      ensure
        [in_r, in_w, out_r, err_r].each { |io| io.close unless io.closed? }
      end
    end
  end
end
