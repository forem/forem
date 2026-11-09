require "rails_helper"

RSpec.describe Organizations::DeleteCustomDomainWorker, type: :worker do
  let(:subscription_id) { "subs_123" }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
  end

  it "deletes the subscription via FastlyTls::Client" do
    allow(FastlyTls::Client).to receive(:delete_subscription).and_return(true)
    
    described_class.new.perform(subscription_id)
    
    expect(FastlyTls::Client).to have_received(:delete_subscription).with(subscription_id)
  end

  it "raises an error if the API call fails so Sidekiq can retry" do
    allow(FastlyTls::Client).to receive(:delete_subscription).and_raise(FastlyTls::Client::Error.new("Network Error"))
    
    expect {
      described_class.new.perform(subscription_id)
    }.to raise_error(FastlyTls::Client::Error)
  end

  context "when Cloudflare is configured instead of Fastly" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return("cf_token")
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_ZONE_ID").and_return("cf_zone")
    end

    it "deletes the custom hostname via CloudflareTls::Client" do
      allow(CloudflareTls::Client).to receive(:delete_subscription).and_return(true)

      described_class.new.perform(subscription_id)

      expect(CloudflareTls::Client).to have_received(:delete_subscription).with(subscription_id)
    end
  end
end
