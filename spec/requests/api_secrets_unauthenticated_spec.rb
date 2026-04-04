require "rails_helper"

# Regression tests for GitHub issues:
#   - https://github.com/forem/forem/issues/23031
#   - https://github.com/forem/forem/issues/23090
#
# Root cause: ApiSecretsController had no `before_action :authenticate_user!`.
# When an unauthenticated user submitted the API key form, Pundit raised
# ApplicationPolicy::UserRequiredError, which is mapped to :not_found in
# config/application.rb — so users saw a 404 "page not found" instead of
# being redirected to login.

RSpec.describe "ApiSecrets unauthenticated access", type: :request, proper_status: true do
  describe "POST /users/api_secrets (unauthenticated)" do
    it "redirects to the magic link sign-in page" do
      post "/users/api_secrets", params: { api_secret: { description: "My App" } }
      expect(response).to redirect_to(new_magic_link_path)
    end

    it "does not create an API secret" do
      expect do
        post "/users/api_secrets", params: { api_secret: { description: "My App" } }
      end.not_to change(ApiSecret, :count)
    end
  end

  describe "DELETE /users/api_secrets/:id (unauthenticated)" do
    let(:api_secret) { create(:api_secret) }

    it "redirects to the magic link sign-in page" do
      delete "/users/api_secrets/#{api_secret.id}"
      expect(response).to redirect_to(new_magic_link_path)
    end

    it "does not delete the API secret" do
      api_secret # ensure created before the expect block
      expect do
        delete "/users/api_secrets/#{api_secret.id}"
      end.not_to change(ApiSecret, :count)
    end
  end
end
