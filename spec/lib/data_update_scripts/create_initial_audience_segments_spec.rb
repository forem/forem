require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20230330152319_create_initial_audience_segments.rb",
)

describe DataUpdateScripts::CreateInitialAudienceSegments do
  it "creates necessary segments" do
    expect do
      described_class.new.run
    end.to change(AudienceSegment, :count).by(12)
  end
end
