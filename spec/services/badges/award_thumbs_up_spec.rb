require "rails_helper"

RSpec.describe Badges::AwardThumbsUp, type: :service do
  let(:thumbs_up_tiers) { described_class::THUMBS_UP_BADGES.keys }

  it "does nothing if there are no thumbsup badges" do
    user = create(:user)
    allow(described_class).to receive(:get_user_thumbsup_counts).and_return(user.id => thumbs_up_tiers.max)

    expect { described_class.call }.not_to change { user.badges.count }
  end

  it "awards the correct badge to the correct user" do
    all_badges = described_class::THUMBS_UP_BADGES.map do |_, badge_title|
      create(:badge, title: badge_title)
    end
    ghost_user = create(:user)
    user = create(:user)
    prolific_user = create(:user)

    allow(described_class).to receive(:get_user_thumbsup_counts)
      .and_return(user.id => thumbs_up_tiers.min, prolific_user.id => thumbs_up_tiers.max)
    described_class.call
    expect(ghost_user.badges.count).to eq(0)
    expect(user.badges).to eq([Badge.find_by(title: described_class::THUMBS_UP_BADGES[thumbs_up_tiers.min])])
    expect(prolific_user.badges).to eq(all_badges)
  end
end
