require "rails_helper"

RSpec.describe Profiles::Update, type: :service do
  let(:profile) do
    create(:profile, data: { name: "Sloan Doe", looking_for_work: true, removed: "Bla" })
  end

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    create(:profile_field, label: "Name", input_type: :text_field)
    create(:profile_field, label: "Looking for work", input_type: :check_box)
    Profile.refresh_attributes!
  end

  after(:all) do
    ProfileField.destroy_all
    Profile.refresh_attributes!
  end
  # rubocop:enable RSpec/BeforeAfterAll

  it "correctly typecasts new attributes", :aggregate_failures do
    described_class.call(profile, name: 123, looking_for_work: "false")
    expect(profile.name).to eq "123"
    expect(profile.looking_for_work).to be false
  end

  it "removes old attributes from the profile" do
    expect do
      described_class.call(profile, {})
    end.to change { profile.data.key?("removed") }.to(false)
  end

  it "propagates changes to user", :agregate_failures do
    new_name = "Sloan Doe"
    described_class.call(profile, name: new_name)
    expect(profile.name).to eq new_name
    expect(profile.user[:name]).to eq new_name
  end
end
