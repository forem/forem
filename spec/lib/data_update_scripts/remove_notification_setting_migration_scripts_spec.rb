require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210701134702_remove_notification_setting_migration_scripts.rb",
)

describe DataUpdateScripts::RemoveNotificationSettingMigrationScripts do
  it "removes scripts correctly from the DB", :aggregate_failures do
    described_class::SCRIPTS_TO_REMOVE.each do |script_name|
      create(:data_update_script, file_name: script_name)
    end

    described_class.new.run

    described_class::SCRIPTS_TO_REMOVE.each do |script_name|
      expect(DataUpdateScript.exists?(file_name: script_name)).to be(false)
    end
  end
end
