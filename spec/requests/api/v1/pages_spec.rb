require "rails_helper"

RSpec.describe "Api::V1::Pages" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let!(:page) { create(:page) }

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    before { user.add_role(:admin) }
  end

  context "when unauthenticated and get a page" do
    context "when no page with specified ID" do
      it "returns not found" do
        get api_page_path(1234), headers: v1_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  it "retrieves all pages and renders the collection as json" do
    get api_pages_path, headers: v1_headers
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.size).to eq(1)
    expect(response.parsed_body.first.keys).to \
      contain_exactly(*%w[id title slug description is_top_level_path
                          landing_page body_html body_json body_markdown
                          processed_html social_image template])
  end

  it "retrieves a page and renders it as json" do
    get api_page_path(page.id), headers: v1_headers
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.keys).to \
      contain_exactly(*%w[id title slug description is_top_level_path
                          landing_page body_html body_json body_markdown
                          processed_html social_image template])
  end
end
