require "rails_helper"

RSpec.describe "Admin::RequestRedirects", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  let!(:request_redirect) { RequestRedirect.create!(original_url: "/old", destination_url: "http://new", request_domain: "example.com") }

  describe "Authentication" do
    it "raises error for guests" do
      expect { get admin_request_redirects_path }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "raises error for normal users" do
      sign_in user
      expect { get admin_request_redirects_path }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "GET /admin/request_redirects" do
    before { sign_in admin }

    it "renders the index template" do
      get admin_request_redirects_path
      expect(response).to be_successful
      expect(response.body).to include("Request Redirects")
      expect(response.body).to include("example.com")
    end
  end

  describe "GET /admin/request_redirects/new" do
    before { sign_in admin }

    it "renders the new template" do
      get new_admin_request_redirect_path
      expect(response).to be_successful
    end
  end

  describe "POST /admin/request_redirects" do
    before { sign_in admin }

    context "with valid parameters" do
      it "creates a new RequestRedirect" do
        expect {
          post admin_request_redirects_path, params: { request_redirect: { original_url: "/test", destination_url: "http://test.com", request_domain: "test.com" } }
        }.to change(RequestRedirect, :count).by(1)
        
        expect(response).to redirect_to(admin_request_redirects_path)
      end
    end

    context "with invalid parameters" do
      it "does not create a new RequestRedirect and renders the new template" do
        expect {
          post admin_request_redirects_path, params: { request_redirect: { original_url: "", destination_url: "", request_domain: "" } }
        }.to change(RequestRedirect, :count).by(0)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/request_redirects/:id/edit" do
    before { sign_in admin }

    it "renders the edit template" do
      get edit_admin_request_redirect_path(request_redirect)
      expect(response).to be_successful
    end
  end

  describe "PATCH /admin/request_redirects/:id" do
    before { sign_in admin }

    context "with valid parameters" do
      it "updates the requested RequestRedirect" do
        patch admin_request_redirect_path(request_redirect), params: { request_redirect: { original_url: "/new-old" } }
        request_redirect.reload
        expect(request_redirect.original_url).to eq("/new-old")
        expect(response).to redirect_to(admin_request_redirects_path)
      end
    end

    context "with invalid parameters" do
      it "does not update the RequestRedirect and renders the edit template" do
        patch admin_request_redirect_path(request_redirect), params: { request_redirect: { original_url: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/request_redirects/:id" do
    before { sign_in admin }

    it "destroys the requested RequestRedirect" do
      expect {
        delete admin_request_redirect_path(request_redirect)
      }.to change(RequestRedirect, :count).by(-1)
      
      expect(response).to redirect_to(admin_request_redirects_path)
    end
  end
end
