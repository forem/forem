require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210630041322_migrate_data_to_work_field.rb",
)

describe DataUpdateScripts::MigrateDataToWorkField do
  let!(:user) { create(:user) }
  let(:profile) { user.profile }

  # Since we have use_transactional_fixtures enabled changes in before(:all)
  # will not automatically be rolled back.
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    ProfileField.find_or_create_by(label: "Work", input_type: :text_field)
    Profile.refresh_attributes!
  end

  after(:all) { ProfileField.destroy_by(label: "Work") }
  # rubocop:enable RSpec/BeforeAfterAll

  it "migrates employment titles without employer name" do
    profile.update(employment_title: "Tester")
    expect { described_class.new.run }
      .to change { profile.reload.work }.from(nil).to("Tester")
  end

  it "migrates employment titles and employer name" do
    profile.update(employment_title: "Tester", employer_name: "ACME Inc.")
    expect { described_class.new.run }
      .to change { profile.reload.work }.from(nil).to("Tester at ACME Inc.")
  end

  it "ignores blank employment titles" do
    profile.update(employment_title: "", employer_name: "ACME Inc.")
    expect { described_class.new.run }.not_to change { profile.reload.work }
  end

  it "ignores blank employer names" do
    profile.update(employment_title: "Tester", employer_name: "")
    expect { described_class.new.run }
      .to change { profile.reload.work }.from(nil).to("Tester")
  end
end
