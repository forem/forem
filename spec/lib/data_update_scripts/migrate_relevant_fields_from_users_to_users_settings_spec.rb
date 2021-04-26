require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210423155327_migrate_relevant_fields_from_users_to_users_settings.rb",
)
# rubocop:disable Lint/EmptyBlock
# rubocop:disable RSpec/RepeatedExample
describe DataUpdateScripts::MigrateRelevantFieldsFromUsersToUsersSettings do
  before do
    Users::Setting.destroy_all
  end

  context "when migrating data" do
    before do
      create(:user)
    end

    it "sets the expected number of records" do
      expect do
        described_class.new.run
      end.to change(Users::Setting, :count).from(0).to(1)
    end

    it "sets the correct User records" do
    end

    it "sets the correct Profile records" do
    end

    it "sets the correct types" do
    end

    it "casts data (display_email_on_profile) to the correct types(boolean)" do
    end

    it "sets a fallback value for values that are null" do
    end
  end

  context "when migrating enum settings" do
    it "assigns the correct mapping for enum settings" do
    end

    it "assigns the fallback value when there value passed does not have an enum defined" do
    end
  end

  it "the updated_at and created_at timestamps are more current than the original values" do
  end

  context "when the user id exists in both the users_settings users tables" do
    it "replaces the user_settings values with values from the user table" do
    end
  end
end
# rubocop:enable Lint/EmptyBlock
# rubocop:enable RSpec/RepeatedExample
