require "rails_helper"

RSpec.describe "Api::V1::Admin::RequestRedirects", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let!(:request_redirect) { RequestRedirect.create!(original_url: "/old", destination_url: "http://new", request_domain: "example.com") }

  let(:headers) do
    {
      "api-key" => create(:api_secret, user: admin).secret,
      "Accept" => "application/vnd.forem.api-v1+json"
    }
  end

  let(:user_headers) do
    {
      "api-key" => create(:api_secret, user: user).secret,
      "Accept" => "application/vnd.forem.api-v1+json"
    }
  end

  describe "Authentication" do
    let(:guest_headers) do
      { "Accept" => "application/vnd.forem.api-v1+json" }
    end

    it "returns 401 for guests" do
      get api_admin_request_redirects_path, headers: guest_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for normal users" do
      get api_admin_request_redirects_path, headers: user_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/admin/request_redirects" do
    it "returns a list of redirects" do
      get api_admin_request_redirects_path, headers: headers
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json[0]["original_url"]).to eq("/old")
    end
  end

  describe "POST /api/admin/request_redirects" do
    context "with valid parameters" do
      it "creates a new RequestRedirect" do
        expect {
          post api_admin_request_redirects_path, params: { request_redirect: { original_url: "/test", destination_url: "http://test.com", request_domain: "test.com" } }, headers: headers
        }.to change(RequestRedirect, :count).by(1)
        
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "does not create and returns errors" do
        expect {
          post api_admin_request_redirects_path, params: { request_redirect: { original_url: "" } }, headers: headers
        }.to change(RequestRedirect, :count).by(0)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/admin/request_redirects/:id" do
    context "with valid parameters" do
      it "updates the requested RequestRedirect" do
        patch api_admin_request_redirect_path(request_redirect), params: { request_redirect: { original_url: "/new-old" } }, headers: headers
        request_redirect.reload
        expect(request_redirect.original_url).to eq("/new-old")
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE /api/admin/request_redirects/:id" do
    it "destroys the requested RequestRedirect" do
      expect {
        delete api_admin_request_redirect_path(request_redirect), headers: headers
      }.to change(RequestRedirect, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
  end
end
