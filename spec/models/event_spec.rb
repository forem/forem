require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:event) { create(:event) }

  it "rejects title with over 45 characters" do
    event.title = Faker::Lorem.characters(46)
    expect(event).not_to be_valid
  end

  it "rejects invalid http url" do
    event.location_url = "dev.to"
    expect(event).not_to be_valid
  end 

  it "rejects ends times that are earlier than start times" do
    event.ends_at = Time.now - 50000
    expect(event).not_to be_valid
  end

  it "creates slug for published events" do
    event.published = true
    expect(event).to be_valid
  end
end
