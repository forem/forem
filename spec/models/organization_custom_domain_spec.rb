require "rails_helper"

RSpec.describe Organization do
  let(:organization) { create(:organization) }

  def configure(cloudflare: false, fastly: false)
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return(cloudflare ? "cf_token" : nil)
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return(cloudflare ? "zone_123" : nil)
    allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(fastly ? "test_key" : nil)
  end

  describe "callbacks" do
    it "registers the custom domain lifecycle callbacks" do
      callback_filters = described_class._commit_callbacks.filter_map do |callback|
        callback.filter if callback.kind == :after
      end
      expect(callback_filters).to include(:manage_custom_domain, :release_custom_domain)
    end
  end

  context "with Cloudflare for SaaS configured" do
    before { configure(cloudflare: true, fastly: true) }

    it "marks a newly added domain as pending and enqueues provisioning" do
      expect do
        organization.update!(custom_domain: "blog.example.com")
      end.to change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)

      expect(organization.reload.tls_status).to eq("pending")
    end

    it "deletes the previous Cloudflare hostname and provisions the new domain when the domain changes" do
      organization.update!(custom_domain: "old.example.com")
      organization.update_columns(cloudflare_custom_hostname_id: "hostname_old", tls_status: "issued",
                                  custom_domain_error: "stale")

      expect do
        organization.update!(custom_domain: "new.example.com")
      end.to change(Organizations::DeleteCloudflareCustomHostnameWorker.jobs, :size).by(1)
        .and change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)

      expect(Organizations::DeleteCloudflareCustomHostnameWorker.jobs.last["args"]).to eq(["hostname_old"])
      organization.reload
      expect(organization.cloudflare_custom_hostname_id).to be_nil
      expect(organization.tls_status).to eq("pending")
      expect(organization.custom_domain_error).to be_nil
    end

    it "deletes a legacy Fastly subscription when the domain changes" do
      organization.update!(custom_domain: "old.example.com")
      organization.update_columns(tls_subscription_id: "subs_123", tls_status: "issued")

      expect do
        organization.update!(custom_domain: "new.example.com")
      end.to change(Organizations::DeleteCustomDomainWorker.jobs, :size).by(1)

      expect(organization.reload.tls_subscription_id).to be_nil
    end

    it "releases the hostname and resets status when the domain is removed" do
      organization.update!(custom_domain: "blog.example.com")
      organization.update_columns(cloudflare_custom_hostname_id: "hostname_abc", tls_status: "issued")

      expect do
        organization.update!(custom_domain: nil)
      end.to change(Organizations::DeleteCloudflareCustomHostnameWorker.jobs, :size).by(1)
        .and not_change(Organizations::ProvisionCustomDomainWorker.jobs, :size)

      organization.reload
      expect(organization.tls_status).to eq("not_started")
      expect(organization.cloudflare_custom_hostname_id).to be_nil
    end

    it "clears cached host lookups for the old and new domains" do
      organization.update!(custom_domain: "old.example.com")
      allow(MemoryFirstCache).to receive(:delete).and_call_original

      organization.update!(custom_domain: "new.example.com")

      expect(MemoryFirstCache).to have_received(:delete).with("org_custom_domain_id:old.example.com")
      expect(MemoryFirstCache).to have_received(:delete).with("org_custom_domain_id:new.example.com")
    end

    it "deletes the hostname when the organization is destroyed" do
      organization.update!(custom_domain: "blog.example.com")
      organization.update_columns(cloudflare_custom_hostname_id: "hostname_abc")

      expect do
        organization.destroy!
      end.to change(Organizations::DeleteCloudflareCustomHostnameWorker.jobs, :size).by(1)
    end

    describe "#restart_custom_domain_provisioning!" do
      it "deletes the previous hostname right away and provisions a new one" do
        organization.update!(custom_domain: "blog.example.com")
        organization.update_columns(cloudflare_custom_hostname_id: "hostname_old", tls_status: "failed",
                                    custom_domain_error: "Validation timed out.")
        allow(CloudflareSaas::Client).to receive(:delete_custom_hostname).and_return(true)

        expect do
          organization.restart_custom_domain_provisioning!
        end.to change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)

        expect(CloudflareSaas::Client).to have_received(:delete_custom_hostname).with("hostname_old")
        organization.reload
        expect(organization.tls_status).to eq("pending")
        expect(organization.cloudflare_custom_hostname_id).to be_nil
        expect(organization.custom_domain_error).to be_nil
      end
    end
  end

  context "with only Fastly configured" do
    before { configure(fastly: true) }

    it "provisions through the existing Fastly flow" do
      expect do
        organization.update!(custom_domain: "blog.example.com")
      end.to change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)

      expect(organization.reload.tls_status).to eq("pending")
    end
  end

  context "without a provisioning provider" do
    before { configure }

    it "leaves the domain unmanaged and does not enqueue provisioning" do
      expect do
        organization.update!(custom_domain: "blog.example.com")
      end.not_to change(Organizations::ProvisionCustomDomainWorker.jobs, :size)

      expect(organization.reload.tls_status).to eq("not_started")
    end
  end

  describe "#custom_domain_live?" do
    before do
      configure
      organization.update!(custom_domain: "blog.example.com")
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[organization])
    end

    it "is true once the certificate is issued" do
      organization.update_columns(tls_status: "issued")
      expect(organization.custom_domain_live?).to be(true)
    end

    it "is true for domains configured outside the automated flow" do
      organization.update_columns(tls_status: "not_started")
      expect(organization.custom_domain_live?).to be(true)
    end

    it "is false while the domain is pending" do
      organization.update_columns(tls_status: "pending")
      expect(organization.custom_domain_live?).to be(false)
    end

    it "is false when provisioning failed" do
      organization.update_columns(tls_status: "failed")
      expect(organization.custom_domain_live?).to be(false)
    end

    it "is false when the feature flag is off" do
      organization.update_columns(tls_status: "issued")
      FeatureFlag.disable(:org_custom_domain, FeatureFlag::Actor[organization])
      expect(organization.custom_domain_live?).to be(false)
    end
  end
end
