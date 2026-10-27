require "rails_helper"

RSpec.describe "/admin/content_manager/organizations org features" do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization) }

  before do
    sign_in(admin)
    FeatureFlag.add(:org_readme)
    FeatureFlag.add(:org_lead_forms)
    FeatureFlag.add(:org_verification)
  end

  after do
    FeatureFlag.disable(:org_readme)
    FeatureFlag.disable(:org_lead_forms)
    FeatureFlag.disable(:org_verification)
  end

  describe "PATCH /admin/organizations/:id/update_org_feature" do
    it "enables org_readme for an organization" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_readme", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])).to be(true)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("enabled")
    end

    it "disables org_readme for an organization" do
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_readme", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])).to be(false)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("disabled")
    end

    it "enables org_lead_forms for an organization" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_lead_forms", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[organization])).to be(true)
    end

    it "disables org_lead_forms for an organization" do
      FeatureFlag.enable(:org_lead_forms, FeatureFlag::Actor[organization])

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_lead_forms", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[organization])).to be(false)
    end

    it "creates a note when toggling a feature" do
      expect do
        patch update_org_feature_admin_organization_path(organization),
              params: { feature: "org_readme", enabled: "true" }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.noteable).to eq(organization)
      expect(note.author).to eq(admin)
      expect(note.content).to include("org_readme")
    end

    it "enables org_verification for an organization" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_verification", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_verification, FeatureFlag::Actor[organization])).to be(true)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("enabled")
    end

    it "disables org_verification for an organization" do
      FeatureFlag.enable(:org_verification, FeatureFlag::Actor[organization])

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_verification", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_verification, FeatureFlag::Actor[organization])).to be(false)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("disabled")
    end

    it "rejects unknown feature names" do
      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_evil_feature", enabled: "true" }

      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:error]).to be_present
    end

    context "with audit logging" do
      before { Audit::Subscribe.listen :moderator }

      after { Audit::Subscribe.forget :moderator }

      it "creates an audit log record" do
        expect do
          patch update_org_feature_admin_organization_path(organization),
                params: { feature: "org_readme", enabled: "true" }
        end.to change(AuditLog, :count).by(1)

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
        expect(log.user_id).to eq(admin.id)
        expect(log.data["action"]).to eq("update_org_feature")
        expect(log.data["target_organization_id"]).to eq(organization.id)
        expect(log.data["feature"]).to eq("org_readme")
      end
    end
  end

  # With CACHE_FEATURE_FLAGS_SECONDS set, each Puma worker caches flags in its own
  # in-memory store (config/initializers/flipper.rb). A toggle expires only the cache
  # of the worker that handled the PATCH, so the redirected GET can land on a worker
  # that still holds the old value.
  describe "GET /admin/organizations/:id after a toggle served by a worker with a stale flag cache" do
    let(:stale_worker) do
      cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 1.hour)
      Flipper.new(Flipper::Adapters::ActiveSupportCacheStore.new(Flipper.configuration.adapter, cache))
    end

    def as_stale_worker
      Flipper.instance = stale_worker
      yield
    ensure
      Flipper.instance = nil
    end

    it "shows the state that was just saved, not the cached state" do
      as_stale_worker { get admin_organization_path(organization) }

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_readme", enabled: "true" }

      as_stale_worker { follow_redirect! }

      expect(response.body).to include(I18n.t("views.admin.organizations.org_features.readme.disable"))
      expect(response.body).not_to include(I18n.t("views.admin.organizations.org_features.readme.enable"))
      expect(response.body).to include(I18n.t("views.admin.organizations.org_features.readme.enabled_notice"))
    end

    it "submits the opposite of the saved state on the next click" do
      as_stale_worker { get admin_organization_path(organization) }

      patch update_org_feature_admin_organization_path(organization),
            params: { feature: "org_lead_forms", enabled: "true" }
      as_stale_worker { follow_redirect! }

      form = Nokogiri::HTML(response.body).css("form").detect do |f|
        f.at_css("input[name='feature']")&.[]("value") == "org_lead_forms"
      end
      expect(form.at_css("input[name='enabled']")["value"]).to eq("false")
    end
  end
end
