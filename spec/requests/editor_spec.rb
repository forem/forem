require "rails_helper"

RSpec.describe "Editor", type: :request do
  describe "GET /new" do
    context "when not logged-in" do
      it "does not render markdown form" do
        get "/new"
        expect(response).not_to render_template(:markdown_form)
      end

      it "asks the stray-user to 'Sign In or Create Your Account'" do
        get "/new"
        expect(response.body).to include("Sign In or Create Your Account")
      end
    end
  end

  describe "GET /:article/edit" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "when not logged-in" do
      it "redirects to /enter" do
        get "/#{user.username}/#{article.slug}/edit"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged-in" do
      it "render markdown form" do
        sign_in user
        get "/#{user.username}/#{article.slug}/edit"
        expect(response).to render_template("articles/_markdown_form")
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
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged-in" do
      it "returns json" do
        sign_in user
        post "/articles/preview", headers: headers
        expect(response.content_type).to eq("application/json")
      end
    end
  end
end
