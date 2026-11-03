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

RSpec.describe "ApiSecrets unauthenticated access", :proper_status do
  describe "POST /users/api_secrets (unauthenticated)" do
    it "does not create an API secret and redirects to the magic link sign-in page", :aggregate_failures do
      expect do
        post "/users/api_secrets", params: { api_secret: { description: "My App" } }
      end.not_to change(ApiSecret, :count)

      expect(response).to redirect_to(new_magic_link_path)
    end
  end

  describe "DELETE /users/api_secrets/:id (unauthenticated)" do
    let!(:api_secret) { create(:api_secret) }

    it "does not delete the API secret and redirects to the magic link sign-in page", :aggregate_failures do
      expect do
        delete "/users/api_secrets/#{api_secret.id}"
      end.not_to change(ApiSecret, :count)

      expect(response).to redirect_to(new_magic_link_path)
    end
  end
end
