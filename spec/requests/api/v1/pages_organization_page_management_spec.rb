require "rails_helper"

RSpec.describe "Api::V1::Pages with Resource Admin: OrganizationPageManagement" do
  let(:manager) { create(:user, :single_resource_admin, resource: OrganizationPageManagement) }
  let(:api_secret) { create(:api_secret, user: manager) }
  let(:headers) do
    { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json",
      "api-key" => api_secret.secret }
  end
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:org_page) { create(:page, organization: organization, slug: "#{organization.slug}/docs", position: 1) }

  before do
    FeatureFlag.add(:org_readme)
    FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
  end

  after do
    FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])
  end

  it "is not a member, an organization resource admin, or a page resource admin", :aggregate_failures do
    expect(manager.org_admin?(organization)).to be(false)
    expect(manager.administrative_access_to?(resource: Organization)).to be(false)
    expect(manager.administrative_access_to?(resource: Page)).to be(false)
  end

  describe "POST /api/pages" do
    it "creates an organization page with only organization-page fields", :aggregate_failures do
      expect do
        post api_pages_path,
             params: {
               organization_id: organization.id,
               title: "Showcase",
               body_markdown: "Hello org",
               body_html: "<script>alert(1)</script>",
               body_css: "body { display: none }",
               is_top_level_path: true,
               landing_page: true,
               template: "contained",
               redirect_to_url: "https://example.com"
             }.to_json,
             headers: headers
      end.to change(organization.pages, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(organization.pages.last).to have_attributes(
        slug: "#{organization.slug}/readme",
        template: "full_within_layout",
        is_top_level_path: false,
        landing_page: false,
        body_html: nil,
        body_css: nil,
        redirect_to_url: nil,
      )
    end

    it "refuses an organization without org_readme" do
      expect do
        post api_pages_path,
             params: { organization_id: other_organization.id, title: "X", body_markdown: "X" }.to_json,
             headers: headers
      end.not_to change(Page, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses a site page" do
      expect do
        post api_pages_path,
             params: { title: "Site", slug: "site-page", body_markdown: "X", description: "X" }.to_json,
             headers: headers
      end.not_to change(Page, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PUT /api/pages/:id" do
    it "updates an organization page" do
      create(:page, organization: organization, slug: "#{organization.slug}/readme", position: 0)
      put api_page_path(org_page.id),
          params: { body_markdown: "Updated docs", show_in_navigation: false }.to_json,
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(org_page.reload).to have_attributes(body_markdown: "Updated docs", show_in_navigation: false)
    end

    it "refuses to move a page to another organization" do
      put api_page_path(org_page.id),
          params: { organization_id: other_organization.id, body_markdown: "Moved" }.to_json,
          headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(org_page.reload.organization).to eq(organization)
    end

    it "refuses a page of an organization without org_readme" do
      other_page = create(:page, organization: other_organization, slug: "#{other_organization.slug}/docs")
      put api_page_path(other_page.id), params: { body_markdown: "Changed" }.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses a site page" do
      site_page = create(:page)
      put api_page_path(site_page.id), params: { body_markdown: "Changed" }.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(site_page.reload.body_markdown).not_to eq("Changed")
    end

    it "updates an embed-only HTML page without applying Markdown fields", :aggregate_failures do
      embed = create(:page, organization: organization, template: "embed_html", body_markdown: nil,
                            body_html: "<p>Widget</p>", slug: "#{organization.slug}/embed/widget")
      put api_page_path(embed.id), params: { body_markdown: "Changed", body_html: "<p>Fresh</p>" }.to_json,
                                   headers: headers

      expect(response).to have_http_status(:ok)
      expect(embed.reload).to have_attributes(template: "embed_html", body_markdown: nil, body_html: "<p>Fresh</p>")
    end
  end

  describe "losing access with the same API key" do
    it "is refused once the role is removed", :aggregate_failures do
      request_headers = headers
      put api_page_path(org_page.id), params: { body_markdown: "Before removal" }.to_json, headers: request_headers
      expect(response).to have_http_status(:ok)

      manager.remove_role(:single_resource_admin, OrganizationPageManagement)
      put api_page_path(org_page.id), params: { body_markdown: "Changed" }.to_json, headers: request_headers

      expect(response).to have_http_status(:unauthorized)
      expect(org_page.reload.body_markdown).to eq("Before removal")
    end

    it "is refused once org_readme is turned off for the organization", :aggregate_failures do
      request_headers = headers
      put api_page_path(org_page.id), params: { body_markdown: "Before disable" }.to_json, headers: request_headers
      expect(response).to have_http_status(:ok)

      FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization])
      put api_page_path(org_page.id), params: { body_markdown: "Changed" }.to_json, headers: request_headers

      expect(response).to have_http_status(:unauthorized)
      expect(org_page.reload.body_markdown).to eq("Before disable")
    end
  end

  describe "DELETE /api/pages/:id" do
    it "refuses to delete an organization page" do
      delete api_page_path(org_page.id), headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(Page.exists?(org_page.id)).to be(true)
    end
  end

  describe "POST /api/pages/preview" do
    it "renders markdown in the organization's context" do
      post preview_api_pages_path,
           params: { organization_id: organization.id, body_markdown: "## Org Preview" }.to_json,
           headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["processed_html"]).to include("Org Preview")
    end

    it "refuses a preview for an organization without org_readme" do
      post preview_api_pages_path,
           params: { organization_id: other_organization.id, body_markdown: "## Org Preview" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses a preview without an organization" do
      post preview_api_pages_path, params: { body_html: "<p>raw</p>" }.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "audit log" do
    before { Audit::Subscribe.listen :admin_api }
    after { Audit::Subscribe.forget :admin_api }

    it "records that the write came through the role" do
      put api_page_path(org_page.id), params: { body_markdown: "Audited" }.to_json, headers: headers

      expect(AuditLog.last).to have_attributes(user_id: manager.id, slug: "api_page_update")
      expect(AuditLog.last.data).to eq("action" => "api_page_update", "page_id" => org_page.id,
                                       "via" => "org_pages_resource_admin",
                                       "organization_id" => organization.id)
    end

    it "does not mark a write by an organization admin who also holds the role" do
      create(:organization_membership, user: manager, organization: organization, type_of_user: "admin")
      put api_page_path(org_page.id), params: { body_markdown: "Audited" }.to_json, headers: headers

      expect(AuditLog.last.data).to eq("action" => "api_page_update", "page_id" => org_page.id)
    end
  end

  describe "everything outside the organization pages API" do
    it "refuses PUT /api/organizations/:id" do
      put api_organization_path(organization.id), params: { organization: { summary: "X" } }.to_json,
                                                  headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    context "when signed in to the admin area" do
      before { sign_in manager }

      it "refuses the organization admin, including Fully Trusted and Verified", :aggregate_failures do
        expect { get admin_organization_path(organization) }.to raise_error(Pundit::NotAuthorizedError)
        expect do
          patch update_fully_trusted_admin_organization_path(organization), params: { fully_trusted: "1" }
        end.to raise_error(Pundit::NotAuthorizedError)
        expect do
          patch update_verified_admin_organization_path(organization), params: { verified: "1" }
        end.to raise_error(Pundit::NotAuthorizedError)
        expect do
          patch update_org_feature_admin_organization_path(organization), params: { feature: "org_readme" }
        end.to raise_error(Pundit::NotAuthorizedError)
      end

      it "refuses Enable for All Orgs and the admin pages", :aggregate_failures do
        expect do
          patch toggle_global_admin_org_features_path, params: { feature: "org_readme", enabled: "true" }
        end.to raise_error(Pundit::NotAuthorizedError)
        expect { get admin_pages_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
