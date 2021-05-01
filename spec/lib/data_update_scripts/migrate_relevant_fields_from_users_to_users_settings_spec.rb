require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210423155327_migrate_relevant_fields_from_users_to_users_settings.rb",
)

describe DataUpdateScripts::MigrateRelevantFieldsFromUsersToUsersSettings do
  before do
    Users::Setting.destroy_all
    Profile.destroy_all
    User.destroy_all
  end

  context "when migrating data" do
    it "sets the expected number of records" do
      create_list(:user, 3)

      expect do
        described_class.new.run
      end.to change(Users::Setting, :count).from(0).to(3)
    end

    it "sets the correct User records" do
      create(:user, config_font: "sans_serif")

      described_class.new.run

      expect(Users::Setting.last.config_font).to eq("sans_serif")
    end

    it "sets the correct Profile records" do
      profile = create(
        :profile,
        :with_DEV_info,
        user: create(:user, :without_profile),
        display_email_on_profile: true,
      )

      described_class.new.run

      expect(Users::Setting.last.display_email_on_profile).to eq(profile.display_email_on_profile)
    end

    it "sets the correct types" do
      create(:user)

      described_class.new.run

      expect(Users::Setting.last.permit_adjacent_sponsors).to be_in([true, false])
    end

    it "casts data (display_email_on_profile) to the correct types (boolean)" do
      create(
        :profile,
        :with_DEV_info,
        user: create(:user, :without_profile),
        display_email_on_profile: true,
      )

      described_class.new.run

      expect(Users::Setting.last.display_email_on_profile).to be_in([true, false])
    end

    it "sets a fallback value for values that are null" do
      create(:user, display_announcements: nil)

      described_class.new.run

      expect(Users::Setting.last.display_announcements).to eq(true)
    end
  end

  context "when migrating enum settings" do
    it "assigns the correct mapping for enum settings" do
      create(:user, config_font: "monospace")

      described_class.new.run

      expect(Users::Setting.first.monospace?).to be(true)
    end

    # Not sure how to test this; when I pass in an invalid font, the spec errors with
    # "Validation failed: Config font fake_font is not a valid font selection"
    it "assigns the fallback value when there value passed does not have an enum defined" do
      create(:user)

      described_class.new.run

      expect(Users::Setting.first.default?).to be(true)
    end
  end

  it "the updated_at and created_at timestamps are more current than the original values" do
    user = create(:user, created_at: 1.minute.ago, updated_at: 1.minute.ago)

    described_class.new.run

    expect(Users::Setting.first.created_at).to be > user.created_at
    expect(Users::Setting.first.updated_at).to be > user.updated_at
  end

  context "when the user id exists in both the users_settings users tables" do
    it "replaces the user_settings values with values from the user table" do
      user = create(:user, display_announcements: true)
      user_id = user.id

      described_class.new.run

      expect(Users::Setting.first.user_id).to eq(user_id)
      expect(Users::Setting.first.display_announcements).to be(true)

      user.update_column(:display_announcements, false)
      user.reload

      described_class.new.run

      expect(Users::Setting.first.user_id).to eq(user_id)
      expect(Users::Setting.first.display_announcements).to be(false)
    end
  end
end
