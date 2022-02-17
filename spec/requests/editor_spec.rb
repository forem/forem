require "rails_helper"

RSpec.describe "Editor", type: :request do
  describe "GET /new" do
    subject(:request_call) { get new_path }

    let(:user) { create(:user) }

    context "when not authenticated" do
      it { within_block_is_expected.to raise_error ApplicationPolicy::UserRequiredError }
    end

    context "when authenticated but not authorized" do
      before do
        login_as user
        allow(ArticlePolicy).to receive(:limit_post_creation_to_admins?).and_return(true)
      end

      # [@jeremyf] We're handling the authentication and authorization exceptions just a bit
      #            differently.  In this case (e.g. they don't have permission) we are relying on
      #            the application configuration to gracefully handle the authorization error (as it
      #            has prior and up to <2022-02-17 Thu>).
      it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
    end

    context "when authenticated and authorized" do
      before { login_as user }

      it "is a successful response" do
        # We have lots of Cypress tests of the behavior of the `/new` page.  Let's make sure we're
        # verifying AuthN/AuthZ things.
        get new_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /:article/edit" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }

    context "when not logged-in" do
      it "redirects to /enter" do
        get "/#{user.username}/#{article.slug}/edit"
        expect(response).to redirect_to(sign_up_path)
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

    context "with front matter" do
      it "returns successfully" do
        sign_in user
        article_body = <<~MARKDOWN
          ---
          ---

          Hello
        MARKDOWN

        post "/articles/preview",
             headers: headers,
             params: { article_body: article_body },
             as: :json

        expect(response).to be_successful
      end
    end
  end
end
