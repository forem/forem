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

  context "when unauthenticated and post a new page" do
    it "returns unauthorized" do
      post api_pages_path, params: { title: "Doesn't Matter" }.to_json, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthenticated and update a page" do
    it "returns unauthorized" do
      put api_page_path(page.id), params: page.attributes.merge(title: "Doesn't Matter").to_json, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthenticated and delete a page" do
    it "returns unauthorized" do
      delete api_page_path(page.id), headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated but not authorized to edit pages" do
    let(:non_auth_header) do
      non_admin_secret = create(:api_secret)
      v1_headers.merge "api-key" => non_admin_secret.secret
    end

    it "returns unauthorized from create" do
      post api_pages_path, params: { title: "Also Doesn't Matter" }.to_json, headers: non_auth_header
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorize from update" do
      put api_page_path(page.id), params: page.attributes.merge(title: "Doesn't Matter").to_json,
                                  headers: non_auth_header
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorize from destroy" do
      delete api_page_path(page.id), headers: non_auth_header
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated and authorized" do
    include_context "when user is authorized"

    let(:post_params) do
      attributes_for(:page)
    end
    let(:body_html) { "<div>hi, folks</div>" }
    let(:body_css) { "h1 {font-size: 120px}" }

    it "can create a new page via post" do
      post api_pages_path, params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
    end

    it "creates a page with body_html" do
      post_params[:body_html] = body_html
      post_params[:body_markdown] = ""
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page.processed_html).to eq(body_html)
    end

    it "creates a page when both body_html and markdown are passed" do
      post_params[:body_html] = body_html
      post_params[:body_markdown] = "other"
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page.processed_html).to include("other")
    end

    it "doesn't create a page when no html or md are passed" do
      post_params[:body_html] = nil
      post_params[:body_markdown] = nil
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page).to be_nil
    end

    it "can update an existing page via put" do
      put api_page_path(page.id), params: page.attributes.merge(title: "Brand New Title").to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.title).to eq("Brand New Title")
    end

    it "updates an existing page via put with body_html" do
      post_params = page.attributes.merge(body_html: body_html, body_markdown: nil)
      put api_page_path(page.id), params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.processed_html).to eq(body_html)
    end

    it "updates an existing page via put when both body_html and body_markdown are passed" do
      post_params = page.attributes.merge(body_html: body_html, body_markdown: "other")
      put api_page_path(page.id), params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.processed_html).to include("other")
    end

    it "creates a page with body_css" do
      post_params[:template] = "css"
      post_params[:body_css] = body_css
      post_params[:body_markdown] = ""
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page.body_css).to eq(body_css)
    end

    it "doesn't create a page when no html or md or css are passed" do
      post_params[:template] = "css"
      post_params[:body_html] = nil
      post_params[:body_markdown] = nil
      post_params[:body_css] = nil
      post api_pages_path, params: post_params.to_json, headers: auth_header
      page = Page.find_by(title: post_params[:title])
      expect(page).to be_nil
    end

    it "updates an existing page via put with body_css" do
      post_params = page.attributes.merge(body_css: body_css, body_markdown: nil, template: "css")
      put api_page_path(page.id), params: post_params.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(page.reload.body_css).to eq(body_css)
    end

    it "can destroy an existing page via delete" do
      delete api_page_path(page.id), headers: auth_header
      expect(response).to have_http_status(:success)
      expect(Page).not_to exist(page.id)
    end
  end

  it "retrieves all pages and renders the collection as json" do
    get api_pages_path, headers: v1_headers
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.size).to eq(1)
    expect(response.parsed_body.first.keys).to \
      match_array(%w[id title slug description is_top_level_path
                     landing_page body_html body_json body_markdown
                     processed_html social_image template])
  end

  it "retrieves a page and renders it as json" do
    get api_page_path(page.id), headers: v1_headers
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.keys).to \
      match_array(%w[id title slug description is_top_level_path
                     landing_page body_html body_json body_markdown
                     processed_html social_image template])
  end
end
