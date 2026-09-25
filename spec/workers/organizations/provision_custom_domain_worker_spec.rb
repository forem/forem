require "rails_helper"

RSpec.describe Organizations::ProvisionCustomDomainWorker, type: :worker do
  let(:organization) { create(:organization, custom_domain: "blog.example.com") }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
  end

  it "creates a subscription and enqueues verification" do
    allow(FastlyTls::Client).to receive(:create_subscription).and_return("subs_123")

    expect do
      described_class.new.perform(organization.id)
    end.to change(Organizations::VerifyCustomDomainWorker.jobs, :size).by(1)

    organization.reload
    expect(organization.tls_subscription_id).to eq("subs_123")
    expect(organization.tls_status).to eq("pending")
    expect(FastlyTls::Client).to have_received(:create_subscription).with("blog.example.com")
  end

  it "does nothing if fastly api key is blank" do
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("")
    allow(FastlyTls::Client).to receive(:create_subscription)

    described_class.new.perform(organization.id)
    expect(FastlyTls::Client).not_to have_received(:create_subscription)
  end

  it "does nothing if tls_subscription_id is already present" do
    organization.update_columns(tls_subscription_id: "subs_existing")
    allow(FastlyTls::Client).to receive(:create_subscription)

    described_class.new.perform(organization.id)
    expect(FastlyTls::Client).not_to have_received(:create_subscription)
  end

  context "with Cloudflare for SaaS" do
    let(:organization) { create(:organization, custom_domain: "blog.example.com") }

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return("cf_token")
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return("zone_123")
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
      allow(FastlyTls::Client).to receive(:create_subscription)
    end

    it "creates a Cloudflare custom hostname instead of a Fastly subscription and enqueues verification" do
      allow(CloudflareSaas::Client).to receive(:create_custom_hostname).and_return({ "id" => "hostname_abc" })

      expect do
        described_class.new.perform(organization.id)
      end.to change(Organizations::VerifyCustomDomainWorker.jobs, :size).by(1)

      organization.reload
      expect(organization.cloudflare_custom_hostname_id).to eq("hostname_abc")
      expect(organization.tls_status).to eq("pending")
      expect(CloudflareSaas::Client).to have_received(:create_custom_hostname).with("blog.example.com")
      expect(FastlyTls::Client).not_to have_received(:create_subscription)
    end

    it "does nothing if a custom hostname already exists" do
      organization.update_columns(cloudflare_custom_hostname_id: "hostname_existing")
      allow(CloudflareSaas::Client).to receive(:create_custom_hostname)

      described_class.new.perform(organization.id)
      expect(CloudflareSaas::Client).not_to have_received(:create_custom_hostname)
    end

    it "marks the domain as failed with Cloudflare's reason when the hostname is rejected" do
      error = CloudflareSaas::Client::Error.new("Cloudflare API Error: Invalid custom hostname.", status: 400)
      allow(CloudflareSaas::Client).to receive(:create_custom_hostname).and_raise(error)

      described_class.new.perform(organization.id)

      organization.reload
      expect(organization.tls_status).to eq("failed")
      expect(organization.custom_domain_error).to eq("Invalid custom hostname.")
      expect(organization.cloudflare_custom_hostname_id).to be_nil
    end

    it "re-raises server errors so Sidekiq retries" do
      error = CloudflareSaas::Client::Error.new("Cloudflare API Error: Service unavailable", status: 503)
      allow(CloudflareSaas::Client).to receive(:create_custom_hostname).and_raise(error)

      expect { described_class.new.perform(organization.id) }.to raise_error(CloudflareSaas::Client::Error)
      expect(organization.reload.tls_status).to eq("pending")
    end

    it "deletes the new hostname if the domain changed while it was being created" do
      allow(CloudflareSaas::Client).to receive(:create_custom_hostname) do
        organization.update_columns(custom_domain: "other.example.com")
        { "id" => "hostname_abc" }
      end
      allow(CloudflareSaas::Client).to receive(:delete_custom_hostname)

      described_class.new.perform(organization.id)

      expect(CloudflareSaas::Client).to have_received(:delete_custom_hostname).with("hostname_abc")
      expect(organization.reload.cloudflare_custom_hostname_id).to be_nil
    end
  end
end
