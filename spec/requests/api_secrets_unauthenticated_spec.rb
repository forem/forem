require "rails_helper"

# Regression tests for GitHub issues:
#   - https://github.com/forem/forem/issues/23031
#   - https://github.com/forem/forem/issues/23090
#
# Root cause: ApiSecretsController has no `before_action :authenticate_user!`.
# When an unauthenticated user submits the API key form, Pundit raises
# ApplicationPolicy::UserRequiredError, which is mapped to :not_found in
# config/application.rb — so users see a 404 "page not found" instead of
# being redirected to login.

RSpec.describe "ApiSecrets unauthenticated access", type: :request, proper_status: true do
  describe "POST /users/api_secrets (unauthenticated)" do
    it "redirects to authentication" do
      post "/users/api_secrets", params: { api_secret: { description: "My App" } }
      expect(response).to have_http_status(:redirect)
    end

    it "does not create an API secret" do
      expect do
        post "/users/api_secrets", params: { api_secret: { description: "My App" } }
      end.not_to change(ApiSecret, :count)
    end
  end

  describe "DELETE /users/api_secrets/:id (unauthenticated)" do
    let(:api_secret) { create(:api_secret) }

    it "redirects to authentication" do
      delete "/users/api_secrets/#{api_secret.id}"
      expect(response).to have_http_status(:redirect)
    end

    it "does not delete the API secret" do
      api_secret # ensure created before the expect block
      expect do
        delete "/users/api_secrets/#{api_secret.id}"
      end.not_to change(ApiSecret, :count)
    end
  end

  describe "POST /users/api_secrets with invalid CSRF token" do
    before do
      sign_in create(:user)
      allow_any_instance_of(ApplicationController).to receive(:verify_authenticity_token)
        .and_raise(ActionController::InvalidAuthenticityToken)
    end

    it "returns 422 unprocessable entity" do
      post "/users/api_secrets", params: { api_secret: { description: "My App" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create an API secret" do
      expect do
        post "/users/api_secrets", params: { api_secret: { description: "My App" } }
      end.not_to change(ApiSecret, :count)
    end
  end

  describe "DELETE /users/api_secrets/:id with invalid CSRF token" do
    let(:api_secret) { create(:api_secret) }

    before do
      sign_in api_secret.user
      allow_any_instance_of(ApplicationController).to receive(:verify_authenticity_token)
        .and_raise(ActionController::InvalidAuthenticityToken)
    end

    it "returns 422 unprocessable entity" do
      delete "/users/api_secrets/#{api_secret.id}"
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not delete the API secret" do
      expect do
        delete "/users/api_secrets/#{api_secret.id}"
      end.not_to change(ApiSecret, :count)
    end
  end
end
