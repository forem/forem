require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201120001727_populate_explicit_follow_points.rb",
)

describe DataUpdateScripts::PopulateExplicitFollowPoints do
  it "updates follows that had points to having explicit points", :aggregate_failures do
    follow = create(:follow, points: 3)
    second_follow = create(:follow, points: 7)
    third_follow = create(:follow, points: 1)
    fourth_follow = create(:follow, points: 0.5)
    expect(follow.explicit_points).to eq(1.0)
    expect(second_follow.explicit_points).to eq(1.0)
    described_class.new.run
    expect(follow.reload.explicit_points).to eq(3)
    expect(second_follow.reload.explicit_points).to eq(7)
    expect(third_follow.reload.explicit_points).to eq(1)
    expect(fourth_follow.reload.explicit_points).to eq(0.5)
  end
end
