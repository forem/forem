require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Users" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  let(:banned_user) { create(:user) }
  let(:article) { create(:article, user: banned_user, published: true) }
  let(:comment) { create(:comment, user: banned_user, article: article) }

  before do
    user.add_role(:admin)
  end

  describe "PUT /users/:id/suspend" do
    before do
      user.add_role(:admin)
    end

    path "/api/users/{id}/suspend" do
      put "Suspend a User" do
        tags "users"
        description "This endpoint allows the client to suspend a user.

The user associated with the API key must have any 'admin' or 'moderator' role.

This specified user will be assigned the 'suspended' role. Suspending a user will stop the
user from posting new posts and comments. It doesn't delete any of the user's content, just
prevents them from creating new content while suspended. Users are not notified of their suspension
in the UI, so if you want them to know about this, you must notify them."
        operationId "suspendUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the user to suspend.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        response "204", "User successfully unpublished" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:regular_user) { create(:user) }
          let(:low_security_api_secret) { create(:api_secret, user: regular_user) }
          let(:"api-key") { low_security_api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "404", "Unknown User ID" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "PUT /users/:id/limited" do
    before do
      user.add_role(:admin)
    end

    path "/api/users/{id}/limited" do
      put "Add limited role for a User" do
        tags "users"
        description "This endpoint allows the client to limit a user.

The user associated with the API key must have any 'admin' or 'moderator' role.

This specified user will be assigned the 'limited' role. Limiting a user will limit notifications
generated from new posts and comments. It doesn't delete any of the user's content or prevent them
from generating new content while limited. Users are not notified of their limits
in the UI, so if you want them to know about this, you must notify them."
        operationId "limitUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the user to limit.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        response "204", "User successfully limited" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:regular_user) { create(:user) }
          let(:low_security_api_secret) { create(:api_secret, user: regular_user) }
          let(:"api-key") { low_security_api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "404", "Unknown User ID" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "DELETE /users/:id/limited" do
    before do
      user.add_role(:admin)
    end

    path "/api/users/{id}/limited" do
      delete "Remove limited for a User" do
        tags "users"
        description "This endpoint allows the client to remove limits for a user.

The user associated with the API key must have any 'admin' or 'moderator' role.

This specified user will be restored to 'general' status. Users are not notified
of limits in the UI, so if you want them to know about this, you must
notify them."
        operationId "unLimitUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the user to un-limit.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        response "204", "User successfully un-limited" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:regular_user) { create(:user) }
          let(:low_security_api_secret) { create(:api_secret, user: regular_user) }
          let(:"api-key") { low_security_api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "404", "Unknown User ID" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end
      end
    end
  end
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
