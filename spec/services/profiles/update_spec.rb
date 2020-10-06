require "rails_helper"

RSpec.describe Profiles::Update, type: :service do
  let(:profile) do
    create(:profile, data: { name: "Sloan Doe", looking_for_work: true, removed: "Bla" })
  end
  let(:user) { profile.user }

  before do
    create(:profile_field, label: "Name", input_type: :text_field)
    create(:profile_field, label: "Looking for work", input_type: :check_box)
    Profile.refresh_attributes!
  end

  it "only tries to sync changes to User if the profile update succeeds" do
    service = described_class.new(user, profile: {}, user: {})
    allow(service).to receive(:update_profile).and_return(false)

    expect(service).not_to receive(:sync_to_user) # rubocop:disable RSpec/MessageSpies
    service.call
  end

  it "correctly typecasts new attributes", :aggregate_failures do
    described_class.call(user, profile: { name: 123, looking_for_work: "false" })
    expect(profile.name).to eq "123"
    expect(profile.looking_for_work).to be false
  end

  it "removes old attributes from the profile" do
    expect do
      described_class.call(user, profile: {})
    end.to change { profile.data.key?("removed") }.to(false)
  end

  it "propagates changes to user", :agregate_failures do
    new_name = "Sloan Doe"
    described_class.call(user, profile: {}, user: { name: new_name })
    expect(profile.name).to eq new_name
    expect(profile.user[:name]).to eq new_name
  end

  it "sets custom attributes for the user" do
    custom_profile_field = create(:custom_profile_field, profile: profile)
    custom_attribute = custom_profile_field.attribute_name

    described_class.call(user, profile: { custom_attribute => "Test" }, user: {})
    expect(profile.custom_attributes[custom_attribute]).to eq "Test"
  end

  it "performs additional actions after successful updates", :agregate_failures do
    allow(RssReaderFetchUserWorker).to receive(:perform_async).with(user.id)
    allow(user).to receive(:feed_url).and_return("https://example.com/feed")

    expect do
      described_class.call(user, profile: { name: 123, looking_for_work: "false" })
    end.to change { user.reload.profile_updated_at }

    expect(RssReaderFetchUserWorker).to have_received(:perform_async)
  end
end
