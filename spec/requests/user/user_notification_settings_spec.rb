require "rails_helper"

RSpec.describe "UserNotificationSettings", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "PUT /update/:id" do
    it "disables reaction notifications (in both users and notification_settings tables)" do
      expect(user.notification_setting.reaction_notifications).to be(true)

      expect do
        put users_notification_settings_path(user.notification_setting.id),
            params: { users_notification_setting: { tab: "notifications", reaction_notifications: 0 } }
      end.to change { user.notification_setting.reload.reaction_notifications }.from(true).to(false)
    end

    it "enables community-success notifications" do
      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", mod_roundrobin_notifications: 1 } }
      expect(user.reload.subscribed_to_mod_roundrobin_notifications?).to be(true)
    end

    it "disables community-success notifications" do
      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", mod_roundrobin_notifications: 0 } }
      expect(user.reload.subscribed_to_mod_roundrobin_notifications?).to be(false)
    end

    it "can toggle welcome notifications" do
      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", welcome_notifications: 0 } }
      expect(user.reload.subscribed_to_welcome_notifications?).to be(false)

      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", welcome_notifications: 1 } }
      expect(user.reload.subscribed_to_welcome_notifications?).to be(true)
    end

    it "returns error message if settings can't be saved" do
      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", email_digest_periodic: nil } }

      expect(flash[:error]).not_to be_blank
    end
  end

  describe "PATCH /onboarding_notifications_checkbox_update" do
    before { sign_in user }

    it "updates onboarding checkbox" do
      user.update_column(:saw_onboarding, false)

      expect do
        patch onboarding_notifications_checkbox_update_path(format: :json),
              params: { notifications: { tab: "notifications", email_newsletter: 1 } }
      end.to change { user.notification_setting.reload.email_newsletter }.from(false).to(true)
      expect(user.saw_onboarding).to be(true)
    end

    it "can toggle email_newsletter" do
      expect do
        patch onboarding_notifications_checkbox_update_path(format: :json),
              params: { notifications: { tab: "notifications", email_newsletter: 1 } }
      end.to change { user.notification_setting.reload.email_newsletter }.from(false).to(true)

      expect do
        patch onboarding_notifications_checkbox_update_path(format: :json),
              params: { notifications: { tab: "notifications", email_newsletter: 0 } }
      end.to change { user.notification_setting.reload.email_newsletter }.from(true).to(false)
    end

    it "can toggle email_digest_periodic" do
      expect do
        patch onboarding_notifications_checkbox_update_path(format: :json),
              params: { notifications: { tab: "notifications", email_digest_periodic: 1 } }
      end.to change { user.notification_setting.reload.email_digest_periodic }.from(false).to(true)

      expect do
        patch onboarding_notifications_checkbox_update_path(format: :json),
              params: { notifications: { tab: "notifications", email_digest_periodic: 0 } }
      end.to change { user.notification_setting.reload.email_digest_periodic }.from(true).to(false)
    end

    it "returns 422 status and errors if errors occur" do
      patch onboarding_notifications_checkbox_update_path(format: :json),
            params: { notifications: { tab: "notifications", email_digest_periodic: nil } }

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).not_to be_blank
    end
  end
end
