require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210423155327_migrate_relevant_fields_from_users_to_users_settings.rb",
)

describe DataUpdateScripts::MigrateRelevantFieldsFromUsersToUsersSettings, sidekiq: :inline do
  let(:users_setting) { Users::Setting.last }

  before do
    Users::Setting.destroy_all
    Profile.destroy_all
    User.destroy_all
  end

  # NOTE: an after_commit in User model creates a users_notification_settings record for users
  # So in these specs, we destroy these users_notification_settings records
  # so that he migration script creates them instead
  context "when migrating data" do
    it "sets the expected number of records" do
      create_list(:user, 3)
      Users::Setting.destroy_all

      expect do
        described_class.new.run
      end.to change(Users::Setting, :count).from(0).to(3)
    end

    it "sets the correct User records" do
      user = create(:user, config_font: "sans_serif")
      user.setting.destroy

      described_class.new.run

      expect(users_setting.config_font).to eq("sans_serif")
    end

    it "sets the correct Profile records" do
      profile = create(
        :profile,
        :with_DEV_info,
        user: create(:user, :without_profile),
        display_email_on_profile: true,
      )

      described_class.new.run

      expect(users_setting.display_email_on_profile).to eq(profile.display_email_on_profile)
    end

    it "sets the correct types" do
      create(:user)

      described_class.new.run

      expect(users_setting.permit_adjacent_sponsors).to be_in([true, false])
    end

    it "casts data (display_email_on_profile) to the correct types (boolean)" do
      create(
        :profile,
        :with_DEV_info,
        user: create(:user, :without_profile),
        display_email_on_profile: true,
      )

      described_class.new.run

      expect(users_setting.display_email_on_profile).to be_in([true, false])
    end

    it "sets a fallback value for values that are null" do
      user = create(:user)
      user.setting.destroy
      user.update_columns(display_announcements: nil)
      user.reload

      described_class.new.run

      expect(users_setting.display_announcements).to be(true)
    end
  end

  context "when migrating enum settings" do
    it "assigns the correct mapping for enum settings" do
      user = create(:user, config_font: "monospace")
      user.setting.destroy

      described_class.new.run

      expect(users_setting.monospace_font?).to be(true)
    end

    it "assigns the fallback value when the value passed does not have an enum defined" do
      user = create(:user)
      user.setting.destroy
      user.update_columns(config_font: "fake_font")
      user.reload

      described_class.new.run

      expect(users_setting.default?).to be(true)
    end
  end

  it "assigns updated_at and created_at timestamps that are more current than the original values" do
    user = create(:user, created_at: 1.minute.ago, updated_at: 1.minute.ago)

    described_class.new.run

    expect(users_setting.created_at).to be > user.created_at
    expect(users_setting.updated_at).to be > user.updated_at
  end

  context "when the user id exists in both the users_settings and users tables" do
    it "replaces the users_settings values with values from the users table" do
      user = create(:user, display_announcements: true)
      user_id = user.id

      described_class.new.run

      expect(users_setting.user_id).to eq(user_id)
      expect(users_setting.display_announcements).to be(true)

      user.update_columns(display_announcements: false)

      described_class.new.run
      users_setting.reload

      expect(users_setting.user_id).to eq(user_id)
      expect(users_setting.display_announcements).to be(false)
    end
  end
end
