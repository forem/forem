require "rails_helper"

RSpec.describe "UserNotificationSettings" do
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
      expect(user.notification_setting.reload.mod_roundrobin_notifications).to be(true)
    end

    it "disables community-success notifications" do
      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", mod_roundrobin_notifications: 0 } }
      expect(user.notification_setting.reload.mod_roundrobin_notifications).to be(false)
    end

    it "can toggle welcome notifications" do
      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", welcome_notifications: 0 } }
      expect(user.notification_setting.reload.subscribed_to_welcome_notifications?).to be(false)

      put users_notification_settings_path(user.notification_setting.id),
          params: { users_notification_setting: { tab: "notifications", welcome_notifications: 1 } }
      expect(user.notification_setting.reload.subscribed_to_welcome_notifications?).to be(true)
    end

    it "coerces blank boolean parameters (e.g. email_newsletter='') to false without raising NotNullViolation" do
      user.notification_setting.update!(email_newsletter: true)

      expect do
        patch users_notification_settings_path,
              params: {
                users_notification_setting: {
                  email_newsletter: "",
                  email_digest_periodic: "0",
                  email_comment_notifications: "0"
                }
              }
      end.not_to raise_error

      expect(response).to redirect_to(user_settings_path(:notifications))
      expect(flash[:settings_notice]).to eq(I18n.t("users_controller.notifications_settings_updated"))
      expect(user.notification_setting.reload.email_newsletter).to be(false)
      expect(user.notification_setting.email_comment_notifications).to be(false)
    end
  end
end
