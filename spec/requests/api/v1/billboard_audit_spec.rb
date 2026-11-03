require "rails_helper"

RSpec.describe "Billboard API audit logs" do
  let(:admin) { create(:user, :admin) }
  let(:api_secret) { create(:api_secret, user: admin) }
  let(:headers) do
    { "Accept" => "application/vnd.forem.api-v1+json", "content-type" => "application/json",
      "api-key" => api_secret.secret }
  end
  let(:billboard) { create(:billboard, published: true) }
  let(:billboard_params) do
    { name: "Community announcement", body_markdown: "Announcement text", placement_area: "post_comments",
      type_of: "in_house", display_to: "all" }
  end

  before { Audit::Subscribe.listen :admin_api }
  after { Audit::Subscribe.forget :admin_api }

  it "logs a creation without content or credentials" do
    post api_billboards_path, params: billboard_params.to_json, headers: headers

    expect(response).to have_http_status(:created)
    expect_audit("api_billboard_create", response.parsed_body["id"])
  end

  it "logs an update" do
    put api_billboard_path(billboard.id), params: { body_markdown: "Updated text" }.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect_audit("api_billboard_update", billboard.id)
  end

  it "logs an unpublish" do
    put unpublish_api_billboard_path(billboard.id), headers: headers

    expect(response).to have_http_status(:no_content)
    expect(billboard.reload.published).to be(false)
    expect_audit("api_billboard_unpublish", billboard.id)
  end

  it "logs writes through the display_ads alias" do
    put api_display_ad_path(billboard.id), params: { name: "Updated announcement" }.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect_audit("api_billboard_update", billboard.id)
  end

  it "does not log an invalid creation" do
    post api_billboards_path, params: billboard_params.merge(display_to: "invalid").to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
  end

  it "does not log an invalid update" do
    put api_billboard_path(billboard.id), params: { display_to: "invalid" }.to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
  end

  it "does not log an unauthorized write" do
    admin.remove_role(:admin)
    put api_billboard_path(billboard.id), params: { name: "Updated announcement" }.to_json, headers: headers

    expect(response).to have_http_status(:unauthorized)
    expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
  end

  def expect_audit(action, id)
    log = AuditLog.last
    expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
    expect(log.user_id).to eq(admin.id)
    expect(log.slug).to eq(action)
    expect(log.data).to eq("action" => action, "billboard_id" => id)
  end
end
