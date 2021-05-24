require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210503174302_migrate_relevant_fields_from_users_to_users_notification_settings.rb",
)

describe DataUpdateScripts::MigrateRelevantFieldsFromUsersToUsersNotificationSettings do
  let(:users_notification_setting) { Users::NotificationSetting.last }

  before do
    Users::NotificationSetting.destroy_all
    User.destroy_all
  end

  context "when migrating data" do
    it "sets the expected number of records" do
      create_list(:user, 3)

      expect do
        described_class.new.run
      end.to change(Users::NotificationSetting, :count).from(0).to(3)
    end

    it "sets the correct User records" do
      create(:user, welcome_notifications: true)

      described_class.new.run

      expect(users_notification_setting.welcome_notifications).to be(true)
    end

    it "sets the correct types" do
      create(:user)

      described_class.new.run

      expect(users_notification_setting.reaction_notifications).to be_in([true, false])
    end

    it "sets a fallback value for values that are null" do
      create(:user, email_newsletter: nil)

      described_class.new.run

      expect(users_notification_setting.email_newsletter).to be(false)
    end
  end

  it "assigns updated_at and created_at timestamps that are more current than the original values" do
    user = create(:user, created_at: 1.minute.ago, updated_at: 1.minute.ago)

    described_class.new.run

    expect(users_notification_setting.created_at).to be > user.created_at
    expect(users_notification_setting.updated_at).to be > user.updated_at
  end

  context "when the user id exists in both the users_notification_settings and users tables" do
    it "replaces the users_notification_settings values with values from the users table" do
      user = create(:user, email_newsletter: true)
      user_id = user.id

      described_class.new.run

      expect(users_notification_setting.user_id).to eq(user_id)
      expect(users_notification_setting.email_newsletter).to be(true)

      user.update_columns(email_newsletter: false)

      described_class.new.run
      users_notification_setting.reload

      expect(users_notification_setting.user_id).to eq(user_id)
      expect(users_notification_setting.email_newsletter).to be(false)
    end
  end
end
