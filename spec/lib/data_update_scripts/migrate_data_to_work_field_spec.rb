require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210630041322_migrate_data_to_work_field.rb",
)

describe DataUpdateScripts::MigrateDataToWorkField, sidekiq: :inline do
  let!(:user) { create(:user) }
  let(:profile) { user.profile }

  before do
    ProfileField.find_or_create_by!(label: "Work", input_type: :text_field)
    Profile.refresh_attributes!
  end

  it "migrates employment titles without employer name" do
    profile.update!(employment_title: "Tester")
    expect { described_class.new.run }
      .to change { profile.reload.work }.from(nil).to("Tester")
  end

  it "migrates employment titles and employer name" do
    profile.update!(employment_title: "Tester", employer_name: "ACME Inc.")
    expect { described_class.new.run }
      .to change { profile.reload.work }.from(nil).to("Tester at ACME Inc.")
  end

  it "ignores blank employment titles" do
    profile.update!(employment_title: "", employer_name: "ACME Inc.")
    expect { described_class.new.run }.not_to change { profile.reload.work }
  end

  it "ignores blank employer names" do
    profile.update!(employment_title: "Tester", employer_name: "")
    expect { described_class.new.run }
      .to change { profile.reload.work }.from(nil).to("Tester")
  end

  # Regression spec for https://github.com/forem/forem/issues/14188
  it "does not accidentally update employment_title" do
    profile.update!(employment_title: "Tester", employer_name: "ACME Inc.")
    expect { described_class.new.run }.not_to change { profile.reload.employment_title }
  end
end
