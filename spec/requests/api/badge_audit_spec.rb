require "rails_helper"

RSpec.describe "Badge API audit logs" do
  ["application/json", "application/vnd.forem.api-v1+json"].each do |accept|
    context "with #{accept}" do
      let(:admin) { create(:user, :admin) }
      let(:api_secret) { create(:api_secret, user: admin) }
      let(:headers) { { "Accept" => accept, "api-key" => api_secret.secret } }
      let(:badge) { create(:badge) }
      let(:achievement) { create(:badge_achievement) }

      before { Audit::Subscribe.listen :admin_api }
      after { Audit::Subscribe.forget :admin_api }

      it "logs a badge creation without content or credentials" do
        image = fixture_file_upload(Rails.root.join("spec/support/fixtures/images/image1.jpeg"), "image/jpeg")
        post api_badges_path,
             params: { badge: { title: "API award", description: "Award description", badge_image: image } },
             headers: headers

        expect(response).to have_http_status(:created)
        expect_audit("api_badge_create", "badge_id" => response.parsed_body["id"])
      end

      it "logs a badge update" do
        patch api_badge_path(badge.id), params: { badge: { title: "Updated award" } }, headers: headers

        expect(response).to have_http_status(:ok)
        expect_audit("api_badge_update", "badge_id" => badge.id)
      end

      it "logs a badge deletion" do
        delete api_badge_path(badge.id), headers: headers

        expect(response).to have_http_status(:no_content)
        expect(Badge.exists?(badge.id)).to be(false)
        expect_audit("api_badge_destroy", "badge_id" => badge.id)
      end

      it "logs an achievement creation with the badge and recipient ids" do
        recipient = create(:user)
        post api_badge_achievements_path,
             params: { badge_achievement: { user_id: recipient.id, badge_id: badge.id,
                                            rewarding_context_message_markdown: "Award message" } },
             headers: headers

        expect(response).to have_http_status(:created)
        expect(AuditLog.on_user(recipient)).to include(AuditLog.last)
        expect_audit("api_badge_achievement_create", "badge_achievement_id" => response.parsed_body["id"],
                                                     "badge_id" => badge.id, "user_id" => recipient.id,
                                                     "target_user_id" => recipient.id)
      end

      it "logs an achievement deletion with the badge and recipient ids" do
        recipient = achievement.user
        delete api_badge_achievement_path(achievement.id), headers: headers

        expect(response).to have_http_status(:no_content)
        expect(BadgeAchievement.exists?(achievement.id)).to be(false)
        expect(AuditLog.on_user(recipient)).to include(AuditLog.last)
        expect_audit("api_badge_achievement_destroy", "badge_achievement_id" => achievement.id,
                                                      "badge_id" => achievement.badge_id,
                                                      "user_id" => achievement.user_id,
                                                      "target_user_id" => recipient.id)
      end

      it "does not log an invalid badge creation" do
        post api_badges_path, params: { badge: { title: "" } }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an invalid badge update" do
        patch api_badge_path(badge.id), params: { badge: { title: "" } }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an invalid achievement creation" do
        post api_badge_achievements_path, params: { badge_achievement: { badge_id: badge.id } }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log a duplicate achievement" do
        post api_badge_achievements_path,
             params: { badge_achievement: { badge_id: achievement.badge_id, user_id: achievement.user_id } },
             headers: headers

        expect(response).to have_http_status(:conflict)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an unauthorized badge deletion" do
        admin.remove_role(:admin)
        delete api_badge_path(badge.id), headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an unauthorized achievement deletion" do
        admin.remove_role(:admin)
        delete api_badge_achievement_path(achievement.id), headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an aborted badge deletion" do
        allow(Badge).to receive(:find).with(badge.id.to_s).and_return(badge)
        allow(badge).to receive(:destroy).and_return(false)

        delete api_badge_path(badge.id), headers: headers

        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an aborted achievement deletion" do
        allow(BadgeAchievement).to receive(:find).with(achievement.id.to_s).and_return(achievement)
        allow(achievement).to receive(:destroy).and_return(false)

        delete api_badge_achievement_path(achievement.id), headers: headers

        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      def expect_audit(action, ids)
        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.user_id).to eq(admin.id)
        expect(log.slug).to eq(action)
        expect(log.data).to eq(ids.merge("action" => action))
      end
    end
  end
end
