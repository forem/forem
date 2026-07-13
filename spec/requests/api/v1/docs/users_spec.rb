require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

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

  describe "GET /users/me" do
    path "/api/users/me" do
      get "The authenticated user" do
        tags "users"
        description "This endpoint allows the client to retrieve information about the authenticated user"
        operationId "getUserMe"
        produces "application/json"

        response 200, "successful" do
          let(:"api-key") { api_secret.secret }
          schema type: :object,
                 items: { "$ref": "#/components/schemas/MyUser" }
          add_examples
          run_test!
        end

        response "401", "Unauthorized" do
          let(:"api-key") { "bad_api_secret" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /users/{id}" do
    path "/api/users/{id}" do
      get "A User" do
        tags "users"
        description "This endpoint allows the client to retrieve a single user, either by id or by the user's username."
        operationId "getUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :string }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          let(:id) { user.id }
          schema type: :object,
                 items: { "$ref": "#/components/schemas/ExtendedUser" }

          run_test!
        end
      end
    end
  end

  describe "GET /users/search" do
    path "/api/users/search" do
      get "Search for users" do
        tags "users"
        description "Search for users by email."
        operationId "searchUsers"
        produces "application/json"
        parameter name: :email, in: :query, required: true, schema: { type: :string }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          let(:email) { user.email }
          schema "$ref": "#/components/schemas/ExtendedUser"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PUT /users/{id}/unpublish" do
    before do
      user.add_role(:admin)
    end

    path "/api/users/{id}/unpublish" do
      put "Unpublish a User's Articles and Comments" do
        tags "users"
        description "This endpoint allows the client to unpublish all of the articles and comments created by a user."
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
      end
    end
  end

  describe "POST /api/admin/users" do
    before do
      user.add_role(:super_admin)
    end

    path "/api/admin/users" do
      post "Invite a User" do
        tags "users", "admin"
        description "This endpoint allows the client to trigger an invitation to the provided email address."
        operationId "postAdminUsersCreate"
        produces "application/json"
        consumes "application/json"
        parameter name: :invitation,
                  in: :body,
                  description: "User invite params",
                  schema: { "$ref": "#/components/schemas/UserInviteParam" }

        response "200", "Successful" do
          let(:"api-key") { api_secret.secret }
          let(:invitation) { { name: "User McUser", email: "user@mcuser.com" } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/admin/users" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users" do
      get "List all users (Admin)" do
        tags "users", "admin"
        produces "application/json"
        parameter name: :page, in: :query, required: false, schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false, schema: { type: :integer }
        parameter name: :email, in: :query, required: false, schema: { type: :string }
        parameter name: :username, in: :query, required: false, schema: { type: :string }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/admin/users/{id}" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{id}" do
      get "Get user detail (Admin)" do
        tags "users", "admin"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:id) { user.id }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PATCH /api/admin/users/{id}" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{id}" do
      patch "Update user profile (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :user_params, in: :body, schema: {
          type: :object,
          properties: {
            name: { type: :string },
            username: { type: :string },
            summary: { type: :string },
            location: { type: :string },
            website_url: { type: :string }
          }
        }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          let(:user_params) { { name: "Updated Name via Admin" } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PUT /api/admin/users/{id}/email" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{id}/email" do
      put "Update user email (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :email_params, in: :body, schema: {
          type: :object,
          properties: {
            email: { type: :string }
          },
          required: [:email]
        }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          let(:email_params) { { email: "new-email@example.com" } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PUT /api/admin/users/{id}/status" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{id}/status" do
      put "Update user moderation status (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :status_params, in: :body, schema: {
          type: :object,
          properties: {
            status: { type: :string },
            note: { type: :string }
          },
          required: [:status]
        }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          let(:status_params) { { status: "Suspended", note: "Violated terms" } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PUT /api/admin/users/{id}/notification_settings" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{id}/notification_settings" do
      put "Update user notification settings (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :settings_params, in: :body, schema: {
          type: :object,
          properties: {
            notification_setting: {
              type: :object,
              properties: {
                email_newsletter: { type: :boolean }
              }
            }
          },
          required: [:notification_setting]
        }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          let(:settings_params) { { notification_setting: { email_newsletter: false } } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/admin/users/{id}/merge" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{id}/merge" do
      post "Merge user into another (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }
        parameter name: :merge_params, in: :body, schema: {
          type: :object,
          properties: {
            merge_user_id: { type: :integer }
          },
          required: [:merge_user_id]
        }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:id) { user.id }
          let(:another_user) { create(:user) }
          let(:merge_params) { { merge_user_id: another_user.id } }

          before do
            allow(Moderator::MergeUser).to receive(:call)
          end

          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/admin/users/{user_id}/notes" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{user_id}/notes" do
      get "List notes for a user (Admin)" do
        tags "users", "admin"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:user_id) { banned_user.id }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/admin/users/{user_id}/notes" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{user_id}/notes" do
      post "Add a note to a user (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true, schema: { type: :integer }
        parameter name: :note_params, in: :body, schema: {
          type: :object,
          properties: {
            content: { type: :string },
            reason: { type: :string }
          },
          required: [:content]
        }

        response "201", "created" do
          let(:"api-key") { api_secret.secret }
          let(:user_id) { banned_user.id }
          let(:note_params) { { content: "Spammer alert", reason: "spam" } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/admin/users/{user_id}/identities" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{user_id}/identities" do
      get "List identities for a user (Admin)" do
        tags "users", "admin"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:user_id) { banned_user.id }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/admin/users/{user_id}/identities" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{user_id}/identities" do
      post "Link an identity to a user (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true, schema: { type: :integer }
        parameter name: :identity_params, in: :body, schema: {
          type: :object,
          properties: {
            provider: { type: :string },
            uid: { type: :string },
            username: { type: :string }
          },
          required: %w[provider uid]
        }

        before do
          allow(Authentication::Providers).to receive(:enabled?).and_return(true)
        end

        response "201", "created" do
          let(:"api-key") { api_secret.secret }
          let(:user_id) { banned_user.id }
          let(:identity_params) { { provider: "github", uid: "12345", username: "testgithub" } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "DELETE /api/admin/users/{user_id}/identities/{id}" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/{user_id}/identities/{id}" do
      delete "Unlink an identity from a user (Admin)" do
        tags "users", "admin"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true, schema: { type: :integer }
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "204", "no content" do
          let(:"api-key") { api_secret.secret }
          let(:user_id) { banned_user.id }
          let!(:identity) { create(:identity, user: banned_user, auth_data_dump: { "info" => {} }) }
          let(:id) { identity.id }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/admin/users/identities/bulk" do
    before { user.add_role(:super_admin) }

    path "/api/admin/users/identities/bulk" do
      post "Bulk link identities (Admin)" do
        tags "users", "admin"
        consumes "application/json"
        produces "application/json"
        parameter name: :bulk_params, in: :body, schema: {
          type: :object,
          properties: {
            provider: { type: :string },
            identities: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  user_id: { type: :integer },
                  uid: { type: :string }
                },
                required: %w[user_id uid]
              }
            }
          },
          required: %w[provider identities]
        }

        before do
          allow(Authentication::Providers).to receive(:enabled?).and_return(true)
        end

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:bulk_params) { { provider: "github", identities: [{ user_id: banned_user.id, uid: "bulk123" }] } }
          add_examples
          run_test!
        end
      end
    end
  end
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable Layout/LineLength
