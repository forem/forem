require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::BadgeAchievements" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin) { create(:user, :super_admin) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:achievement) { create(:badge_achievement) }

  describe "GET /badge_achievements" do
    path "/api/badge_achievements" do
      get "Retrieve all badge achievements" do
        tags "badge_achievements"
        produces "application/json"
        parameter name: :page, in: :query, required: false, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          schema type: :array, items: { "$ref": "#/components/schemas/BadgeAchievement" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/badge_achievements" do
    path "/api/badge_achievements" do
      post "Create a badge achievement" do
        tags "badge_achievements"
        consumes "application/json"
        produces "application/json"
        parameter name: :achievement_params, in: :body, schema: {
          type: :object,
          properties: {
            badge_achievement: {
              type: :object,
              properties: {
                user_id: { type: :integer },
                badge_id: { type: :integer },
                rewarding_context_message_markdown: { type: :string },
                include_default_description: { type: :boolean }
              },
              required: %w[user_id badge_id]
            }
          }
        }

        response "201", "created" do
          let(:"api-key") { admin_api_secret.secret }
          let(:another_user) { create(:user) }
          let(:another_badge) { create(:badge) }
          let(:achievement_params) { { badge_achievement: { user_id: another_user.id, badge_id: another_badge.id, rewarding_context_message_markdown: "Nice job", include_default_description: true } } }
          schema "$ref": "#/components/schemas/BadgeAchievement"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/badge_achievements/{id}" do
    path "/api/badge_achievements/{id}" do
      get "Retrieve a badge achievement's details" do
        tags "badge_achievements"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "200", "successful" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { achievement.id }
          schema "$ref": "#/components/schemas/BadgeAchievement"
          add_examples
          run_test!
        end
      end
    end
  end

  describe "DELETE /api/badge_achievements/{id}" do
    path "/api/badge_achievements/{id}" do
      delete "Delete a badge achievement" do
        tags "badge_achievements"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }

        response "204", "no content" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { achievement.id }
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
