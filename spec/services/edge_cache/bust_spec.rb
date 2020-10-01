require "rails_helper"

RSpec.describe EdgeCache::Bust, type: :service do
  let(:user) { create(:user) }
  let(:path) { "/#{user.username}" }

  describe "#bust_fastly_cache" do
    let(:fastly_provider_class) { EdgeCache::Bust::Fastly }

    context "when fastly is not configured" do
      before do
        stub_fastly
        stub_nginx
      end

      let(:cache_bust_service) { described_class.new(path) }

      it "does not bust a fastly cache" do
        allow(fastly_provider_class).to receive(:call)

        cache_bust_service.call
        expect(cache_bust_service.provider).to be(nil)
        expect(fastly_provider_class).not_to have_received(:call)
      end
    end

    context "when fastly is configured" do
      before do
        configure_fastly
        stub_nginx
      end

      let(:cache_bust_service) { described_class.new(path) }

      it "can bust a fastly cache" do
        allow(fastly_provider_class).to receive(:call)

        cache_bust_service.call
        expect(cache_bust_service.provider).to eq("fastly")
        expect(fastly_provider_class).to have_received(:call)
      end

      it "returns cache bust response" do
        allow(fastly_provider_class).to receive(:call).and_return("success")

        cache_bust_service.call
        expect(cache_bust_service.response).to eq("success")
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

    context "when openresty is not configured" do
      before do
        stub_nginx
      end

      let(:cache_bust_service) { described_class.new(path) }

      it "does not bust an nginx cache" do
        allow(nginx_provider_class).to receive(:call)

        cache_bust_service.call
        expect(cache_bust_service.provider).to eq(nil)
        expect(nginx_provider_class).not_to have_received(:call)
      end
    end

    context "when openresty is configured and available" do
      before do
        configure_nginx
      end

      let(:cache_bust_service) { described_class.new(path) }

      it "can bust an nginx cache" do
        allow(nginx_provider_class).to receive(:call)

        cache_bust_service.call
        expect(cache_bust_service.provider).to eq("nginx")
        expect(nginx_provider_class).to have_received(:call)
      end
    end
  end

  def stub_fastly
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)
  end

  def stub_nginx
    allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_PROTOCOL").and_return(nil)
    allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_DOMAIN").and_return(nil)
  end

  def configure_fastly
    allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("fake-domain")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service-id")
  end

  def configure_nginx
    allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_PROTOCOL").and_return("http://")
    allow(ApplicationConfig).to receive(:[]).with("OPENRESTY_DOMAIN").and_return("localhost:9090")
  end
end
