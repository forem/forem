require "rails_helper"

RSpec.describe "Editor", type: :request do
  describe "GET /new" do
    context "when not logged-in" do
      it "asks the non logged in user to sign in" do
        get new_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Password")
      end
    end
  end

  describe "GET /:article/edit" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "when not logged-in" do
      it "redirects to /enter" do
        get "/username/article/edit"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged-in" do
      it "render markdown form" do
        sign_in user
        get "/#{user.username}/#{article.slug}/edit"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /articles/preview" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }
    let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }

    context "when not logged-in" do
      it "redirects to /enter" do
        post "/articles/preview", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged-in" do
      it "returns json" do
        sign_in user
        post "/articles/preview", headers: headers
        expect(response.media_type).to eq("application/json")
      end
    end
  end
end
