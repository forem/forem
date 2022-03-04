require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210503202046_remove_unused_data_update_scripts.rb",
)

describe DataUpdateScripts::RemoveUnusedDataUpdateScripts do
  it "doesn't raise an error if no DataUpdateScripts are found" do
    stub_const "#{described_class}::FILE_NAMES", ["non_existant_data_update_script"]
    result = described_class.new.run
    expect(result).to eq(0) # delete_by returns 0 if no records are found
  end

  it "deletes all the unused DataUpdateScripts" do
    data_update_script = create(:data_update_script)
    stub_const "#{described_class}::FILE_NAMES", [data_update_script.file_name]

    expect(DataUpdateScript.find_by(file_name: data_update_script.file_name)).to be_present
    described_class.new.run
    expect(DataUpdateScript.find_by(file_name: data_update_script.file_name)).not_to be_present
  end

  it "doesn't delete valid DataUpdateScripts" do
    stub_const "#{described_class}::FILE_NAMES", ["non_existant_data_update_script"]

    data_update_script = create(:data_update_script)
    expect(DataUpdateScript.find_by(file_name: data_update_script.file_name)).to be_present
    described_class.new.run
    expect(DataUpdateScript.find_by(file_name: data_update_script.file_name)).to be_present
  end
end
