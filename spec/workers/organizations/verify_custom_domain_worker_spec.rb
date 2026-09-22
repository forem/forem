require "rails_helper"

RSpec.describe Organizations::VerifyCustomDomainWorker, type: :worker do
  let(:organization) { create(:organization, custom_domain: "blog.example.com", tls_subscription_id: "subs_123", tls_status: "pending") }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("test_key")
  end

  it "updates status to issued if fastly returns issued" do
    allow(FastlyTls::Client).to receive(:get_subscription).and_return({ "attributes" => { "state" => "issued" } })

    described_class.new.perform(organization.id)
    expect(organization.reload.tls_status).to eq("issued")
  end

  it "re-enqueues if status is pending" do
    allow(FastlyTls::Client).to receive(:get_subscription).and_return({ "attributes" => { "state" => "pending" } })

    expect do
      described_class.new.perform(organization.id)
    end.to change(described_class.jobs, :size).by(1)

    expect(organization.reload.tls_status).to eq("pending")
  end

  it "marks as failed and clears subscription_id if deleted upstream (404 error returned as nil)" do
    allow(FastlyTls::Client).to receive(:get_subscription).and_return(nil)

    described_class.new.perform(organization.id)
    organization.reload
    expect(organization.tls_status).to eq("failed")
    expect(organization.tls_subscription_id).to be_nil
  end

  context "with Cloudflare for SaaS" do
    let(:organization) { create(:organization, custom_domain: "blog.example.com") }

    def hostname_record(status:, ssl_status:, created_at: 10.minutes.ago, **extra)
      {
        "id" => "hostname_abc",
        "hostname" => "blog.example.com",
        "status" => status,
        "ssl" => { "status" => ssl_status, "validation_errors" => extra.fetch(:validation_errors, []) },
        "verification_errors" => extra.fetch(:verification_errors, []),
        "created_at" => created_at.iso8601
      }
    end

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return("cf_token")
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return("zone_123")
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[organization])
      organization.update_columns(cloudflare_custom_hostname_id: "hostname_abc", tls_status: "pending")
    end

    it "marks the domain issued when the hostname and certificate are active, and purges the org's pages" do
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname)
        .and_return(hostname_record(status: "active", ssl_status: "active"))

      expect do
        described_class.new.perform(organization.id)
      end.to change(Organizations::BustCacheWorker.jobs, :size).by(1)

      organization.reload
      expect(organization.tls_status).to eq("issued")
      expect(organization.custom_domain_live?).to be(true)
    end

    it "does not purge again when an already live domain is re-checked" do
      organization.update_columns(tls_status: "issued")
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname)
        .and_return(hostname_record(status: "active", ssl_status: "active"))

      expect do
        described_class.new.perform(organization.id)
      end.not_to change(Organizations::BustCacheWorker.jobs, :size)
    end

    it "stays pending, records Cloudflare's error, and checks again soon while the hostname is new" do
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname).and_return(
        hostname_record(status: "pending", ssl_status: "pending_validation",
                        verification_errors: ["custom hostname does not CNAME to this zone."]),
      )

      expect do
        described_class.new.perform(organization.id)
      end.to change(described_class.jobs, :size).by(1)

      organization.reload
      expect(organization.tls_status).to eq("pending")
      expect(organization.custom_domain_error).to eq("custom hostname does not CNAME to this zone.")
      expect(described_class.jobs.last["at"]).to be_within(5).of(5.minutes.from_now.to_f)
    end

    it "backs off to hourly checks after the first hour" do
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname)
        .and_return(hostname_record(status: "pending", ssl_status: "pending_validation", created_at: 2.hours.ago))

      described_class.new.perform(organization.id)

      expect(described_class.jobs.last["at"]).to be_within(5).of(1.hour.from_now.to_f)
    end

    it "gives up and marks the domain failed after a week" do
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname)
        .and_return(hostname_record(status: "pending", ssl_status: "pending_validation", created_at: 8.days.ago))

      expect do
        described_class.new.perform(organization.id)
      end.not_to change(described_class.jobs, :size)

      expect(organization.reload.tls_status).to eq("failed")
    end

    it "marks the domain failed when certificate validation times out" do
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname).and_return(
        hostname_record(status: "pending", ssl_status: "validation_timed_out",
                        validation_errors: [{ "message" => "Validation timed out." }]),
      )

      described_class.new.perform(organization.id)

      organization.reload
      expect(organization.tls_status).to eq("failed")
      expect(organization.custom_domain_error).to eq("Validation timed out.")
    end

    it "marks the domain failed and clears the reference when the hostname was deleted on Cloudflare" do
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname).and_return(nil)

      described_class.new.perform(organization.id)

      organization.reload
      expect(organization.tls_status).to eq("failed")
      expect(organization.cloudflare_custom_hostname_id).to be_nil
    end

    it "purges the org's pages when a live domain stops being live" do
      organization.update_columns(tls_status: "issued")
      allow(CloudflareSaas::Client).to receive(:get_custom_hostname)
        .and_return(hostname_record(status: "moved", ssl_status: "active"))

      expect do
        described_class.new.perform(organization.id)
      end.to change(Organizations::BustCacheWorker.jobs, :size).by(1)

      expect(organization.reload.tls_status).to eq("failed")
    end
  end
end
