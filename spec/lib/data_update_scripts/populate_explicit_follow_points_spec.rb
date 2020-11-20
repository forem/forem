require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201120001727_populate_explicit_follow_points.rb",
)

describe DataUpdateScripts::PopulateExplicitFollowPoints do
  it "updates follows that had points to having explicit points", :aggregate_failures do
    follow = create(:follow, points: 3)
    expect(follow.explicit_points).to eq(0)
    described_class.new.run
    expect(follow.reload.explicit_points).to eq(3)
  end
end
