require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201120001727_populate_explicit_follow_points.rb",
)

describe DataUpdateScripts::PopulateExplicitFollowPoints do
  it "updates follows that had points to having explicit points", :aggregate_failures do
    follow = create(:follow, points: 3)
    user.add_role(:tag_moderator, tag1)

    expect do
      described_class.new.run
    end.to change { follow.reload.explicit_points }.from(0.0).to(3.0)
  end
end
