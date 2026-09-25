require "rails_helper"

RSpec.describe "Organization custom domain settings" do
  let(:user) { create(:user, :org_admin) }
  let(:organization) { user.organizations.first }
  let(:settings_path) { "/#{organization.slug}/settings" }
  let(:domain_path) { "/#{organization.slug}/settings/custom_domain" }
  let(:check_path) { "/#{organization.slug}/settings/custom_domain/check" }

  def configure_cloudflare(enabled: true)
    allow(ApplicationConfig).to receive(:[]).and_call_original
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return(enabled ? "cf_token" : nil)
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return(enabled ? "zone_123" : nil)
    allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_CNAME_TARGET").and_return(nil)
  end

  before do
    allow(Settings::General).to receive(:app_domain).and_return("forem.com")
    configure_cloudflare
    sign_in user
  end

  context "when the organization has the custom domain feature" do
    before { FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[organization]) }

    it "shows the custom domain section with setup steps" do
      get settings_path

      expect(response.body).to include(%(id="section-custom-domain"))
      expect(response.body).to include("Add custom domain")
      expect(response.body).to include("cname.forem.com")
    end

    it "saves a domain, normalizing a pasted URL, and enqueues provisioning" do
      expect do
        patch domain_path, params: { organization: { custom_domain: "https://Blog.Example.com/some/path" } }
      end.to change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)

      expect(response).to redirect_to("#{settings_path}#section-custom-domain")
      organization.reload
      expect(organization.custom_domain).to eq("blog.example.com")
      expect(organization.tls_status).to eq("pending")
    end

    it "shows DNS instructions and the CNAME target while the domain is pending" do
      organization.update!(custom_domain: "blog.example.com")

      get settings_path

      expect(response.body).to include("Waiting for DNS")
      expect(response.body).to include("<code>blog</code>")
      expect(response.body).to include(%(<code data-testid="custom-domain-cname-target">cname.forem.com</code>))
    end

    it "shows Cloudflare's verification error while pending" do
      organization.update!(custom_domain: "blog.example.com")
      organization.update_columns(custom_domain_error: "custom hostname does not CNAME to this zone.")

      get settings_path

      expect(response.body).to include("custom hostname does not CNAME to this zone.")
    end

    it "shows the domain as live once the certificate is issued" do
      organization.update!(custom_domain: "blog.example.com")
      organization.update_columns(tls_status: "issued")

      get settings_path

      expect(response.body).to include("Your custom domain is live")
      expect(response.body).not_to include("Add this DNS record")
    end

    it "rejects the app domain" do
      patch domain_path, params: { organization: { custom_domain: "sub.forem.com" } }

      expect(flash[:custom_domain_error]).to be_present
      expect(organization.reload.custom_domain).to be_nil
    end

    it "requires a domain" do
      patch domain_path, params: { organization: { custom_domain: "  " } }

      expect(flash[:custom_domain_error]).to eq(I18n.t("views.organization_settings.custom_domain.domain_required"))
    end

    it "rejects a domain another organization already uses" do
      create(:organization, custom_domain: "taken.example.com")

      patch domain_path, params: { organization: { custom_domain: "taken.example.com" } }

      expect(flash[:custom_domain_error]).to be_present
      expect(organization.reload.custom_domain).to be_nil
    end

    it "removes the domain" do
      organization.update!(custom_domain: "blog.example.com")
      organization.update_columns(cloudflare_custom_hostname_id: "hostname_abc")

      expect do
        delete domain_path
      end.to change(Organizations::DeleteCloudflareCustomHostnameWorker.jobs, :size).by(1)

      expect(organization.reload.custom_domain).to be_nil
    end

    describe "checking status" do
      before do
        organization.update!(custom_domain: "blog.example.com")
        Rails.cache.delete("org_custom_domain_check:#{organization.id}")
      end

      it "checks Cloudflare right away and reports a live domain" do
        organization.update_columns(cloudflare_custom_hostname_id: "hostname_abc")
        allow(CloudflareSaas::Client).to receive(:get_custom_hostname).and_return(
          { "id" => "hostname_abc", "status" => "active", "ssl" => { "status" => "active" },
            "created_at" => Time.current.iso8601 },
        )

        post check_path

        expect(flash[:custom_domain_notice]).to eq(I18n.t("views.organization_settings.custom_domain.check_live"))
        expect(organization.reload.tls_status).to eq("issued")
      end

      it "restarts provisioning after a failure" do
        organization.update_columns(cloudflare_custom_hostname_id: "hostname_old", tls_status: "failed")
        allow(CloudflareSaas::Client).to receive(:delete_custom_hostname).and_return(true)

        expect do
          post check_path
        end.to change(Organizations::ProvisionCustomDomainWorker.jobs, :size).by(1)

        expect(flash[:custom_domain_notice]).to eq(I18n.t("views.organization_settings.custom_domain.retry_started"))
        expect(organization.reload.tls_status).to eq("pending")
      end

      it "throttles repeated checks" do
        organization.update_columns(cloudflare_custom_hostname_id: "hostname_abc")
        allow(CloudflareSaas::Client).to receive(:get_custom_hostname).and_return(
          { "id" => "hostname_abc", "status" => "pending", "ssl" => { "status" => "pending_validation" },
            "created_at" => Time.current.iso8601 },
        )
        allow(Rails.cache).to receive(:write).and_call_original
        allow(Rails.cache).to receive(:write)
          .with("org_custom_domain_check:#{organization.id}", true, hash_including(unless_exist: true))
          .and_return(true, false)

        post check_path
        post check_path

        expect(CloudflareSaas::Client).to have_received(:get_custom_hostname).once
        expect(flash[:custom_domain_notice]).to eq(I18n.t("views.organization_settings.custom_domain.check_throttled"))
      end

      it "shows a friendly error when Cloudflare is unreachable" do
        organization.update_columns(cloudflare_custom_hostname_id: "hostname_abc")
        allow(CloudflareSaas::Client).to receive(:get_custom_hostname)
          .and_raise(CloudflareSaas::Client::Error.new("Cloudflare API Error: timeout", status: 504))

        post check_path

        expect(flash[:custom_domain_error]).to eq(I18n.t("views.organization_settings.custom_domain.check_error"))
      end
    end
  end

  context "when the organization does not have the custom domain feature" do
    it "hides the section and rejects changes" do
      get settings_path
      expect(response.body).not_to include(%(id="section-custom-domain"))

      expect do
        patch domain_path, params: { organization: { custom_domain: "blog.example.com" } }
      end.to raise_error(ActiveRecord::RecordNotFound)
      expect(organization.reload.custom_domain).to be_nil
    end
  end

  context "when Cloudflare for SaaS is not configured" do
    before do
      configure_cloudflare(enabled: false)
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[organization])
    end

    it "hides the section and rejects changes" do
      get settings_path
      expect(response.body).not_to include(%(id="section-custom-domain"))

      expect do
        patch domain_path, params: { organization: { custom_domain: "blog.example.com" } }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when the user is not an admin of the organization" do
    let(:member) { create(:user) }

    before do
      create(:organization_membership, user: member, organization: organization, type_of_user: "member")
      FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[organization])
      sign_in member
    end

    it "does not allow changing the domain" do
      expect do
        patch domain_path, params: { organization: { custom_domain: "blog.example.com" } }
      end.to raise_error(Pundit::NotAuthorizedError)

      expect(organization.reload.custom_domain).to be_nil
    end
  end
end
