require "rails_helper"

RSpec.describe "/api/badge_achievements", type: :request do
  let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:admin) { create(:user, :admin) }
  let(:api_secret) { create(:api_secret, user: admin) }
  let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

  let(:user) { create(:user) }
  let(:single_award_badge) { create(:badge, allow_multiple_awards: false) }
  let!(:badge_achievement) { create(:badge_achievement, user: user, badge: single_award_badge) }

  describe "GET /api/badge_achievements" do
    it "returns a successful response" do
      get api_badge_achievements_path, headers: headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/badge_achievements/:id" do
    it "returns the specified achievement" do
      get api_badge_achievement_path(badge_achievement.id), headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(badge_achievement.id)
    end
  end

  describe "POST /api/badge_achievements" do
    let(:award_recipient) { create(:user) }
    let(:badge_to_award) { create(:badge) }
    let(:valid_params) do
      {
        badge_achievement: {
          user_id: award_recipient.id,
          badge_id: badge_to_award.id,
          rewarding_context_message_markdown: "Custom award message.",
          include_default_description: false
        }
      }
    end

    it "creates a new achievement with valid params and extra context" do
      expect do
        post api_badge_achievements_path, params: valid_params, headers: headers
      end.to change(BadgeAchievement, :count).by(1)

      expect(response).to have_http_status(:created)

      new_achievement = BadgeAchievement.last
      expect(new_achievement.rewarding_context_message_markdown).to eq("Custom award message.")
      expect(new_achievement.include_default_description).to be(false)
    end

    it "does not create a duplicate achievement for a single-award badge" do
      duplicate_params = {
        badge_achievement: { user_id: user.id, badge_id: single_award_badge.id }
      }

      expect do
        post api_badge_achievements_path, params: duplicate_params, headers: headers
      end.not_to change(BadgeAchievement, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/badge_achievements/:id" do
    let!(:achievement_to_delete) { create(:badge_achievement) }

    it "deletes the achievement" do
      expect do
        delete api_badge_achievement_path(achievement_to_delete.id), headers: headers
      end.to change(BadgeAchievement, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end