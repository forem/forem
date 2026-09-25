require "rails_helper"

RSpec.describe Organizations::DeleteCloudflareCustomHostnameWorker, type: :worker do
  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return("cf_token")
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return("zone_123")
  end

  it "deletes the custom hostname" do
    allow(CloudflareSaas::Client).to receive(:delete_custom_hostname).and_return(true)

    described_class.new.perform("hostname_abc")

    expect(CloudflareSaas::Client).to have_received(:delete_custom_hostname).with("hostname_abc")
  end

  it "raises so Sidekiq can retry when the API call fails" do
    allow(CloudflareSaas::Client).to receive(:delete_custom_hostname)
      .and_raise(CloudflareSaas::Client::Error.new("Cloudflare API Error: timeout", status: 504))

    expect { described_class.new.perform("hostname_abc") }.to raise_error(CloudflareSaas::Client::Error)
  end

  it "does nothing when Cloudflare is not configured" do
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return(nil)
    allow(CloudflareSaas::Client).to receive(:delete_custom_hostname)

    described_class.new.perform("hostname_abc")

    expect(CloudflareSaas::Client).not_to have_received(:delete_custom_hostname)
  end
end
