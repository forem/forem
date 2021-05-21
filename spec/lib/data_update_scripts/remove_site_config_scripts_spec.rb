require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210518043957_remove_site_config_scripts.rb",
)

describe DataUpdateScripts::RemoveSiteConfigScripts do
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
