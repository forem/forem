require "rails_helper"

RSpec.describe Event, type: :model do
  let(:event) { build(:event) }

  it "rejects title with over 90 characters" do
    event.title = Faker::Lorem.characters(number: 100)
    expect(event).not_to be_valid
  end

  it "rejects invalid http url" do
    event.location_url = "dev.to"
    expect(event).not_to be_valid
  end

  it "rejects ends times that are earlier than start times" do
    event.ends_at = event.starts_at - 1.minute
    expect(event).not_to be_valid
  end

  it "creates slug for published events" do
    event = build(:event, category: "ama", title: "yo", published: true)
    event.validate!
    expected_slug = "#{event.category}-#{event.title}-#{event.starts_at.strftime('%m-%d-%Y')}"
    expect(event.slug).to eq(expected_slug)
  end

  it "triggers cache busting on save" do
    sidekiq_assert_enqueued_jobs(1, queue: "low_priority") do
      event.save
    end
  end
end
