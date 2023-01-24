require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Users", appmap: false do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  let(:banned_user) { create(:user) }
  let(:article) { create(:article, user: banned_user, published: true) }
  let(:comment) { create(:comment, user: banned_user, article: article) }

  before do
    allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true)
    user.add_role(:admin)
  end

  describe "GET /users/:id" do
    path "/api/users/{id}" do
      get "A User" do
        tags "users"
        description "This endpoint allows the client to retrieve a single user, either by id
or by the user's username.

For complete documentation, see the v0 API docs: https://developers.forem.com/api/v0#tag/users/operation/getUser"
        operationId "getUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true, type: :string

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          let(:id) { user.id }

          run_test!
        end
      end
    end
  end

  describe "PUT /users/:id/unpublish" do
    before do
      user.add_role(:admin)
    end

    path "/api/users/{id}/unpublish" do
      put "Unpublish a User's Articles and Comments" do
        tags "users"
        description "This endpoint allows the client to unpublish all of the articles and
comments created by a user.

The user associated with the API key must have any 'admin' or 'moderator' role.

This specified user's articles and comments will be unpublished and will no longer be
visible to the public. They will remain in the database and will set back to draft status
on the specified user's  dashboard. Any notifications associated with the specified user's
articles and comments will be deleted.

Note this endpoint unpublishes articles and comments asychronously: it will return a 204 NO CONTENT
status code immediately, but the articles and comments will not be unpublished until the
request is completed on the server."
        operationId "unpublishUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the user to unpublish.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        response "204", "User's articles and comments successfully unpublished" do
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

        response "404", "Unknown User ID (still accepted for async processing)" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end
      end
    end
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
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
