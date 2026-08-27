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

    it "creates an achievement with metadata" do
      params_with_metadata = valid_params.deep_merge(
        badge_achievement: { metadata: { "entitlement_id" => "abc-123", "source" => "core" } },
      )

      post api_badge_achievements_path, params: params_with_metadata, headers: headers

      expect(response).to have_http_status(:created)
      expect(BadgeAchievement.last.metadata).to eq("entitlement_id" => "abc-123", "source" => "core")
      expect(response.parsed_body["metadata"]).to eq("entitlement_id" => "abc-123", "source" => "core")
    end

    it "defaults metadata to an empty hash when omitted" do
      post api_badge_achievements_path, params: valid_params, headers: headers

      expect(response).to have_http_status(:created)
      expect(BadgeAchievement.last.metadata).to eq({})
    end

    context "when the user already holds a single-award badge" do
      let(:duplicate_params) do
        { badge_achievement: { user_id: user.id, badge_id: single_award_badge.id } }
      end

      it "does not create a duplicate achievement" do
        expect do
          post api_badge_achievements_path, params: duplicate_params, headers: headers
        end.not_to change(BadgeAchievement, :count)
      end

      it "returns 409 with the id of the achievement that blocked it" do
        post api_badge_achievements_path, params: duplicate_params, headers: headers

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body["errors"]).to be_present
        expect(response.parsed_body["achievement_id"]).to eq(badge_achievement.id)
      end
    end

    it "returns 422 for a payload that is invalid for other reasons" do
      invalid_params = { badge_achievement: { user_id: user.id, badge_id: nil } }

      post api_badge_achievements_path, params: invalid_params, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).not_to have_key("achievement_id")
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
