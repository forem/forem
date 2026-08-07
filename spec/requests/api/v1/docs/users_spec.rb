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
        description "This endpoint allows the client to retrieve information about the authenticated user.

### Usage Tips:
- Requires a valid `api-key` header to identify the user.
- Useful for checking permissions, verifying linking state, or retrieving user-specific profile settings."
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
        security []
        description "This endpoint allows the client to retrieve a single user, either by id or by the user's username.

### Path Parameter Options:
- **id**: Can be either the user's unique numerical ID (e.g. `123`) OR the user's string username (e.g. `ben`).
- Note that the returned user object schema (`ExtendedUser`) includes extended profile statistics and social link details."
        operationId "getUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The user's unique numerical ID or string username.",
                  schema: { type: :string }

        response(200, "successful") do
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
        description "Search for a user by email address.

### Permissions & Context:
- Requires administrative privileges (`api-key` of an administrator).
- Used to verify account existence or map email addresses to platform usernames."
        operationId "searchUsers"
        produces "application/json"
        parameter name: :email, in: :query, required: true,
                  description: "The exact email address of the user to search for.",
                  schema: { type: :string }

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
        description "This endpoint allows the client to unpublish all of the articles and comments created by a user.

### Administrative Action:
- Requires the authenticated user to be an Administrator.
- This is a destructive administrative action that immediately unpublishes all posts/comments from public feeds.
- Ideal for handling spam accounts or cleanup operations."
        operationId "unpublishUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The unique numerical ID of the user whose content will be unpublished.",
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
        description "Invite a new user to join the platform by email.

### Super Admin Action:
- Requires Super Admin privileges.
- Triggers a system invitation flow and sends an invitation email containing a sign-up link.
- Handy for invite-only platforms or private enterprise instances."
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
        description "Retrieve a list of all users registered on the platform.

### Permissions & Filters:
- Requires Super Admin privileges.
- Allows filtering by exact `email` or `username`.
- Returns paginated list of extended user objects containing email addresses, registration dates, roles, and administrative statuses."
        produces "application/json"
        parameter name: :page, in: :query, required: false,
                  description: "Pagination page index.",
                  schema: { type: :integer }
        parameter name: :per_page, in: :query, required: false,
                  description: "Number of items to return per page.",
                  schema: { type: :integer }
        parameter name: :email, in: :query, required: false,
                  description: "Optional email search filter.",
                  schema: { type: :string }
        parameter name: :username, in: :query, required: false,
                  description: "Optional username search filter.",
                  schema: { type: :string }

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
        description "Retrieve details of a single user by numerical ID.

### Super Admin Action:
- Requires Super Admin privileges.
- Includes administrative settings, audit notes, email newsletter preferences, and OAuth login identity states."
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique user numeric ID.",
                  schema: { type: :integer }

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
        description "Update a user's public profile fields (name, location, bio summary, website) on their behalf. Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique user ID to update.",
                  schema: { type: :integer }
        parameter name: :user_params, in: :body,
                  description: "User profile updated fields.",
                  schema: {
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
        description "Update a user's primary registration email address. Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique user ID to update email for.",
                  schema: { type: :integer }
        parameter name: :email_params, in: :body,
                  description: "Email parameters.",
                  schema: {
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
        description "Manually update a user's moderation status.

### Status Details:
- **status**: Allowed target states (e.g. `active`, `suspended`, `banned`).
- **note**: Required reason text recorded in the user's moderation log audit history.
- Requires Super Admin privileges."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique user ID.",
                  schema: { type: :integer }
        parameter name: :status_params, in: :body,
                  description: "Status parameters.",
                  schema: {
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
        description "Update a user's email notification preferences (e.g., unsubscribing them from the system newsletter). Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique user ID.",
                  schema: { type: :integer }
        parameter name: :settings_params, in: :body,
                  description: "Settings parameters.",
                  schema: {
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
        description "Merge a duplicate user account into a target main account.

### Account Merging Behavior:
- Transfers all comments, articles, reactions, and follows to the target user (`merge_user_id`).
- Deletes/destroys the source user account once the merge completes successfully.
- High risk! Action is permanent and irreversible.
- Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The duplicate user ID that will be deleted after contents merge.",
                  schema: { type: :integer }
        parameter name: :merge_params, in: :body,
                  description: "Merge parameters containing the target account ID.",
                  schema: {
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
        description "Retrieve all moderator/administrator audit log notes appended to a user. Requires Super Admin credentials."
        produces "application/json"
        parameter name: :user_id, in: :path, required: true,
                  description: "User ID to fetch notes for.",
                  schema: { type: :integer }

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
        description "Add a new moderation/audit note to a user.

### Audit Logging Guidelines:
- **content**: Plaintext description of behavior, infraction, or actions taken.
- **reason**: Categorized classification (e.g. `spam`, `abuse`, `harassment`, `administrative`).
- Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true,
                  description: "User ID to append the note to.",
                  schema: { type: :integer }
        parameter name: :note_params, in: :body,
                  description: "Note attributes.",
                  schema: {
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
        description "Retrieve all linked OAuth identities (e.g., GitHub, Twitter, Apple) for a user. Requires Super Admin credentials."
        produces "application/json"
        parameter name: :user_id, in: :path, required: true,
                  description: "User ID to fetch linked identities for.",
                  schema: { type: :integer }

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
        description "Manually link an OAuth provider identity to a user. Requires Super Admin credentials.

### Identity Binding:
- **provider**: The login provider name (e.g. `github`, `twitter`).
- **uid**: The provider's unique user identifier.
- **username**: The user's username on the provider's service."
        consumes "application/json"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true,
                  description: "User ID to bind identity to.",
                  schema: { type: :integer }
        parameter name: :identity_params, in: :body,
                  description: "OAuth credentials and identities.",
                  schema: {
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
        description "Unlink a specific OAuth login provider identity from a user by identity ID. Requires Super Admin credentials."
        produces "application/json"
        parameter name: :user_id, in: :path, required: true,
                  description: "User ID.",
                  schema: { type: :integer }
        parameter name: :id, in: :path, required: true,
                  description: "Identity ID to unlink.",
                  schema: { type: :integer }

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
        description "Bulk link OAuth identities across multiple users. Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :bulk_params, in: :body,
                  description: "Bulk identity params.",
                  schema: {
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
