require "rails_helper"

RSpec.describe Profiles::Update, type: :service do
  let(:profile) do
    create(:profile, data: { name: "Sloan Doe", check: true, removed: "Bla" })
  end

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    create(:profile_field, label: "Name", input_type: :text_field)
    create(:profile_field, label: "Check", input_type: :check_box)
    Profile.refresh_store_accessors!
  end

  after(:all) do
    ProfileField.destroy_all
    Profile.refresh_store_accessors!
  end
  # rubocop:enable RSpec/BeforeAfterAll

  it "correctly typecasts new attributes", :aggregate_failures do
    described_class.call(profile, name: 123, check: "false")
    expect(profile.name).to eq "123"
    expect(profile.check).to be false
  end

  it "removes old attributes from the profile" do
    expect do
      described_class.call(profile, {})
    end.to change { profile.data.key?("removed") }.to(false)
  end
end
