require "rails_helper"

RSpec.describe "/admin/content_manager/organizations" do
  let(:admin) { create(:user, :without_profile, :super_admin, profile_image: nil) }
  let(:organization) { create(:organization, name: "Original Name") }

  before do
    sign_in(admin)
  end

  describe "GETS /admin/content_manager/organizations" do
    let!(:another_organization) { create(:organization, name: "T-800") }

    before { organization }

    it "lists all organizations" do
      get admin_organizations_path
      expect(response.body).to include(CGI.escapeHTML(organization.name), CGI.escapeHTML(another_organization.name))
    end

    it "allows searching", :aggregate_failures do
      get "#{admin_organizations_path}?search=#{organization.name}"
      expect(response.body).to include(CGI.escapeHTML(organization.name))
      expect(response.body).not_to include(CGI.escapeHTML(another_organization.name))
    end

    it "paginates without COUNT(*) queries and omits heavy columns", :aggregate_failures do
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql]
      end

      begin
        get admin_organizations_path, params: { search: organization.name }
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      org_queries = queries.select { |sql| sql.include?('FROM "organizations"') && sql.exclude?("custom_domain") }
      expect(org_queries.size).to eq(1)
      expect(org_queries.first).not_to include("COUNT(")
      expect(org_queries.first).to include('"organizations"."id"', '"organizations"."name"')
      expect(org_queries.first).not_to include('"secret"', '"cta_body_markdown"', '"story"')
    end
  end

  describe "GET /admin/organizations/:id" do
    it "renders the correct organization" do
      get admin_organization_path(organization.id)
      expect(response.body).to include(CGI.escapeHTML(organization.name))
    end

    it "renders activity counts and batches feature flags without extra COUNT or gate queries", :aggregate_failures do
      create(:article, organization: organization)
      follower = create(:user)
      follower.follow(organization)
      organization.reload

      raw_adapter = FeatureFlag.uncached.adapter
      allow(Organization).to receive(:find).with(organization.id.to_s).and_return(organization)
      allow(organization).to receive(:followers).and_call_original
      allow(organization).to receive(:articles).and_call_original
      allow(raw_adapter).to receive(:get_multi).and_call_original
      allow(raw_adapter).to receive(:get).and_call_original

      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        next if payload[:name] == "SCHEMA"

        queries << payload[:sql]
      end

      begin
        get admin_organization_path(organization.id)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("1 articles")
      expect(response.body).to include("1 followers")
      expect(organization).not_to have_received(:followers)
      expect(organization).not_to have_received(:articles)
      expect(queries.none? { |sql| sql.include?('FROM "articles"') && sql.include?("COUNT(") }).to be(true)
      expect(raw_adapter).to have_received(:get_multi).once
      Admin::OrganizationsController::ORG_FEATURES.each do |flag|
        expect(raw_adapter).not_to have_received(:get).with(have_attributes(key: flag))
      end
    end
  end

  describe "PATCH /admin" do
    it "adds credits to an organization" do
      params = { credits: 1, credit_action: :add }

      expect do
        patch update_org_credits_admin_organization_path(organization),
              params: params
      end.to change { organization.reload.unspent_credits_count }.by(1)
    end

    it "removes credits to an organization" do
      Credit.add_to(organization, 1)
      params = { credits: 1, credit_action: :remove }

      expect do
        patch update_org_credits_admin_organization_path(organization),
              params: params
      end.to change { organization.reload.unspent_credits_count }.by(-1)
    end

    context "with audit logging" do
      before { Audit::Subscribe.listen :moderator }

      after { Audit::Subscribe.forget :moderator }

      it "creates an audit log record" do
        expect do
          patch update_org_credits_admin_organization_path(organization),
                params: { credits: 5, credit_action: :add, note: "test" }
        end.to change(AuditLog, :count).by(1)

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
        expect(log.user_id).to eq(admin.id)
        expect(log.data["action"]).to eq("update_org_credits")
        expect(log.data["target_organization_id"]).to eq(organization.id)
      end
    end
  end

  describe "PATCH /admin/organizations/:id/update_fully_trusted" do
    it "enables fully_trusted status" do
      expect do
        patch update_fully_trusted_admin_organization_path(organization),
              params: { fully_trusted: "true" }
      end.to change { organization.reload.fully_trusted }.from(false).to(true)

      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("enabled")
    end

    it "disables fully_trusted status" do
      organization.update(fully_trusted: true)

      expect do
        patch update_fully_trusted_admin_organization_path(organization),
              params: { fully_trusted: "false" }
      end.to change { organization.reload.fully_trusted }.from(true).to(false)

      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("disabled")
    end
  end

  describe "PATCH /admin/organizations/:id/update_name" do
    it "updates organization name" do
      patch update_name_admin_organization_path(organization), params: { name: "Updated Name" }

      expect(organization.reload.name).to eq("Updated Name")
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to eq(I18n.t("admin.organizations_controller.name_updated"))
    end

    context "with audit logging" do
      before { Audit::Subscribe.listen :moderator }

      after { Audit::Subscribe.forget :moderator }

      it "strips whitespace and records a note and audit log" do
        expect do
          patch update_name_admin_organization_path(organization), params: { name: "  Updated Name  " }
        end.to change(Note, :count).by(1).and change(AuditLog, :count).by(1)

        expect(organization.reload.name).to eq("Updated Name")
        expect(Note.last.content).to include("Original Name", "Updated Name")
        expect(AuditLog.last.data).to include("old_name" => "Original Name", "new_name" => "Updated Name")
      end

      it "does not record a note or audit log when the name is unchanged" do
        expect do
          patch update_name_admin_organization_path(organization), params: { name: "Original Name" }
        end.to not_change(Note, :count).and not_change(AuditLog, :count)
      end
    end

    it "shows errors for invalid name" do
      patch update_name_admin_organization_path(organization), params: { name: "" }

      expect(organization.reload.name).to eq("Original Name")
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:error]).to include("Name")
    end
  end
end
