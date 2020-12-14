require "rails_helper"

RSpec.describe EdgeCache::Bust, type: :service do
  let(:user) { create(:user) }
  let(:path) { "/#{user.username}" }

  it "defines TIMEFRAMES" do
    expect(described_class.const_defined?(:TIMEFRAMES)).to be true
  end

  it "adjusts TIMEFRAMES according to the current time" do
    current_year = Time.current.year

    Timecop.freeze(3.years.ago) do
      timestamp, _interval = described_class::TIMEFRAMES.first
      expect(timestamp.call.year).to be <= current_year - 3
    end
  end

  describe "#bust_fastly_cache" do
    let(:fastly_provider_class) { EdgeCache::Bust::Fastly }

    context "when fastly is not configured" do
      before do
        stub_fastly
        stub_nginx
      end

      it "does not bust a fastly cache" do
        allow(fastly_provider_class).to receive(:call)

        described_class.call(path)
        expect(fastly_provider_class).not_to have_received(:call)
      end
    end

    context "when fastly is configured" do
      before do
        configure_fastly
        stub_nginx
      end

      it "can bust a fastly cache" do
        allow(fastly_provider_class).to receive(:call)

        described_class.call(path)
        expect(fastly_provider_class).to have_received(:call)
      end
    end
  end

  describe "#bust_nginx_cache" do
    let(:nginx_provider_class) { EdgeCache::Bust::Nginx }

    before do
      # Explicitly stub Fastly since we check if Fastly has
      # been configured before we try to use Nginx.
      stub_fastly
    end

    context "when OpenResty is not configured" do
      before do
        stub_nginx
      end

      it "does not bust an nginx cache" do
        allow(nginx_provider_class).to receive(:call)

        described_class.call(path)
        expect(nginx_provider_class).not_to have_received(:call)
      end
    end

    context "when OpenResty is configured and available" do
      before do
        configure_nginx
      end

      let(:cache_bust_service) { described_class.new(path) }

      it "can bust an nginx cache" do
        allow(nginx_provider_class).to receive(:call)

        described_class.call(path)
        expect(nginx_provider_class).to have_received(:call)
      end
    end
  end

  def stub_fastly
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)
  end

  def stub_nginx
    allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_URL").and_return(nil)
  end

  def configure_fastly
    allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("fake-domain")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service-id")
  end

  def configure_nginx
    allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_URL").and_return("http://localhost:9090")
  end
end
