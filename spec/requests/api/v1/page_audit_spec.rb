require "rails_helper"

RSpec.describe "Page API audit logs" do
  let(:admin) { create(:user, :admin) }
  let(:api_secret) { create(:api_secret, user: admin) }
  let(:headers) do
    { "Accept" => "application/vnd.forem.api-v1+json", "content-type" => "application/json",
      "api-key" => api_secret.secret }
  end
  let(:existing_page) { create(:page) }
  let(:page_params) { attributes_for(:page, title: "Community guide", slug: "community-guide") }

  before { Audit::Subscribe.listen :admin_api }
  after { Audit::Subscribe.forget :admin_api }

  it "logs a creation without content or credentials" do
    post api_pages_path, params: page_params.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect_audit("api_page_create", response.parsed_body["id"])
  end

  it "logs an update by a page admin" do
    put api_page_path(existing_page.id), params: { body_markdown: "Updated guide" }.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect_audit("api_page_update", existing_page.id)
  end

  it "logs a deletion" do
    delete api_page_path(existing_page.id), headers: headers

    expect(response).to have_http_status(:ok)
    expect(Page.exists?(existing_page.id)).to be(false)
    expect_audit("api_page_destroy", existing_page.id)
  end

  it "does not log an invalid creation" do
    post api_pages_path, params: page_params.merge(body_markdown: "").to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
  end

  it "does not log an invalid update" do
    put api_page_path(existing_page.id), params: { title: "" }.to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
  end

  it "does not log an unauthorized deletion" do
    admin.remove_role(:admin)
    delete api_page_path(existing_page.id), headers: headers

    expect(response).to have_http_status(:unauthorized)
    expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
  end

  context "when an organization admin manages pages" do
    let(:admin) { create(:user, :org_admin) }
    let(:organization) { admin.organizations.first }
    let(:existing_page) { create(:page, organization: organization) }

    before do
      FeatureFlag.add(:org_readme)
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
    end

    after { FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization]) }

    it "logs a creation by the organization admin" do
      post api_pages_path, params: { organization_id: organization.id, body_markdown: "Organization guide" }.to_json,
                           headers: headers

      expect(response).to have_http_status(:ok)
      expect_audit("api_page_create", response.parsed_body["id"])
    end

    it "logs an update by the organization admin" do
      put api_page_path(existing_page.id), params: { body_markdown: "Updated organization guide" }.to_json,
                                           headers: headers

      expect(response).to have_http_status(:ok)
      expect_audit("api_page_update", existing_page.id)
    end
  end

  it "does not log an aborted page deletion" do
    allow(Page).to receive(:find).with(existing_page.id.to_s).and_return(existing_page)
    allow(existing_page).to receive(:destroy).and_return(false)

    delete api_page_path(existing_page.id), headers: headers

    expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
  end

  def expect_audit(action, id)
    log = AuditLog.last
    expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
    expect(log.user_id).to eq(admin.id)
    expect(log.slug).to eq(action)
    expect(log.data).to eq("action" => action, "page_id" => id)
  end
end
