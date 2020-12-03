require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200901040521_create_profile_fields.rb")

def profile_field_and_group_count
  [ProfileField.count, ProfileFieldGroup.count]
end

describe DataUpdateScripts::CreateProfileFields do
  before do
    ProfileFieldGroup.destroy_all
    ProfileField.destroy_all
  end

  context "when no profile fields or groups exist" do
    it "creates all profile fields and groups" do
      expect do
        described_class.new.run
      end.to change { profile_field_and_group_count }.from([0, 0]).to([28, 5])
    end
  end

  context "when profile fields and/or groups already exist" do
    before do
      csv = Rails.root.join("lib/data/dev_profile_fields.csv")
      ProfileFields::ImportFromCsv.call(csv)
    end

    it "works when profile fields or groups already exist", :aggregate_failures do
      expect do
        described_class.new.run
      end.not_to change { profile_field_and_group_count }
      expect(profile_field_and_group_count).to eq [28, 5]
    end
  end
end
