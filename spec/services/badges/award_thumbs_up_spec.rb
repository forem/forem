require "rails_helper"

RSpec.describe Badges::AwardThumbsUp, type: :service do
  let(:thumbs_up_tiers) { described_class::THUMBS_UP_BADGES.keys }
  let(:user) { create(:user) }

  it "does nothing if there are no thumbsup badges" do
    allow(described_class).to receive(:get_user_thumbsup_counts).and_return(user.id => thumbs_up_tiers.max)

    expect { described_class.call }.not_to change { user.badges.count }
  end

  context "when there are thumbsup badges" do
    let!(:all_badges) do
      described_class::THUMBS_UP_BADGES.map do |_, badge_title|
        create(:badge, title: badge_title)
      end
    end
    let(:min_badge) { Badge.find_by(title: described_class::THUMBS_UP_BADGES[thumbs_up_tiers.min]) }
    let(:ghost_user) { create(:user) }
    let(:prolific_user) { create(:user) }

    it "awards the correct badge to the correct user" do
      allow(described_class).to receive(:get_user_thumbsup_counts)
        .and_return(user.id => thumbs_up_tiers.min, prolific_user.id => thumbs_up_tiers.max)
      described_class.call
      expect(ghost_user.badges.count).to eq(0)
      expect(user.badges).to eq([min_badge])
      expect(prolific_user.badges).to eq(all_badges)
    end

    it "doesn't award badges second time" do
      create(:badge_achievement, user: user, badge: min_badge)
      allow(described_class).to receive(:get_user_thumbsup_counts).and_return(user.id => thumbs_up_tiers.min + 1)
      expect do
        described_class.call
      end.not_to change(user.badge_achievements, :count)
    end
  end
end
