require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Badges" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin) { create(:user, :super_admin) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:badge) { create(:badge) }
  let(:tiny_gif_data) do
    "GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xFF\xFF\xFF!\xF9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x01D\x00;"
  end

  describe "GET /badges" do
    path "/api/badges" do
      get "Retrieve all badges" do
        tags "badges"
        description "Retrieve a list of all badges available on the platform.

### Badges Overview:
- Badges recognize achievements (e.g., \"Top Writer\", \"Beloved Community Member\", or anniversary milestones).
- Publicly visible on user profiles."
        produces "application/json"
        parameter name: :page, in: :query, required: false,
                  description: "Pagination page index.",
                  schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          schema type: :array, items: { "$ref": "#/components/schemas/Badge" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/badges" do
    path "/api/badges" do
      post "Create a badge" do
        tags "badges"
        description "Create a new badge. Requires administrator privileges.

### Body Parameter Guidelines:
- **title**: Unique name for the badge.
- **description**: Text explanation of the achievement.
- **remote_badge_image_url**: Public URL to an image asset (PNG, GIF, or SVG) representing the badge icon.
- **allow_multiple_awards**: Set to `true` if a user can earn the same badge multiple times (e.g. weekly challenges)."
        consumes "application/json"
        produces "application/json"
        parameter name: :badge_params, in: :body,
                  description: "Badge properties to create.",
                  schema: {
                    type: :object,
                    properties: {
                      badge: {
                        type: :object,
                        properties: {
                          title: { type: :string },
                          description: { type: :string },
                          remote_badge_image_url: { type: :string },
                          credits_awarded: { type: :integer },
                          allow_multiple_awards: { type: :boolean }
                        },
                        required: %w[title description remote_badge_image_url]
                      }
                    }
                  }

        before do
          stub_request(:get, "https://example.com/image.png").to_return(status: 200, body: tiny_gif_data)
        end

        response "201", "created" do
          let(:"api-key") { admin_api_secret.secret }
          let(:badge_params) { { badge: { title: "Documentation Badge", description: "Awesome Badge", remote_badge_image_url: "https://example.com/image.png", credits_awarded: 5, allow_multiple_awards: true } } }
          schema "$ref": "#/components/schemas/Badge"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/badges/{id}" do
    path "/api/badges/{id}" do
      get "Retrieve a badge's details" do
        tags "badges"
        description "Retrieve details of a single badge by unique numeric ID."
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique badge ID.",
                  schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { badge.id }
          schema "$ref": "#/components/schemas/Badge"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PATCH /api/badges/{id}" do
    path "/api/badges/{id}" do
      patch "Update a badge" do
        tags "badges"
        description "Update badge details (title, description, credits awarded, etc.) by unique ID. Requires administrator privileges."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique badge ID to update.",
                  schema: { type: :integer }
        parameter name: :badge_params, in: :body,
                  description: "Badge properties to update.",
                  schema: {
                    type: :object,
                    properties: {
                      badge: {
                        type: :object,
                        properties: {
                          title: { type: :string },
                          description: { type: :string },
                          credits_awarded: { type: :integer },
                          allow_multiple_awards: { type: :boolean }
                        }
                      }
                    }
                  }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { badge.id }
          let(:badge_params) { { badge: { title: "Updated Title" } } }
          schema "$ref": "#/components/schemas/Badge"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "DELETE /api/badges/{id}" do
    path "/api/badges/{id}" do
      delete "Delete a badge" do
        tags "badges"
        description "Delete a badge configuration from the system by ID. Requires administrator privileges."
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "Unique badge ID to delete.",
                  schema: { type: :integer }

        response "204", "no content" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { badge.id }
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
