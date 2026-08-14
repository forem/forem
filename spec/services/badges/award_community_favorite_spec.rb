require "rails_helper"

RSpec.describe Badges::AwardCommunityFavorite, type: :service do
  subject(:award) { described_class.call(favoritable: article, favoriter: leader) }

  let(:leader) { create(:user, :community_leader_level_1) }
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }

  before do
    create(:badge, title: "Community Favorite", slug: described_class::BADGE_SLUG,
                   allow_multiple_awards: true)
  end

  it "awards the badge to the author of the favorited article" do
    expect { award }.to change(BadgeAchievement, :count).by(1)
    expect(BadgeAchievement.last.user_id).to eq(author.id)
  end

  it "awards the badge to the author of the favorited comment" do
    comment = create(:comment, commentable: create(:article), user: author)

    expect { described_class.call(favoritable: comment, favoriter: leader) }
      .to change(BadgeAchievement, :count).by(1)
    expect(BadgeAchievement.last.user_id).to eq(author.id)
  end

  it "records the favoriter as the rewarder" do
    award

    expect(BadgeAchievement.last.rewarder_id).to eq(leader.id)
  end

  it "links to the favorited article" do
    award

    expect(BadgeAchievement.last.rewarding_context_message_markdown)
      .to include(URL.article(article))
  end

  it "links to the favorited comment" do
    comment = create(:comment, commentable: article, user: author)

    described_class.call(favoritable: comment, favoriter: leader)

    expect(BadgeAchievement.last.rewarding_context_message_markdown)
      .to include(URL.comment(comment))
  end

  context "when the instance does not have the badge" do
    before { Badge.find_by(slug: described_class::BADGE_SLUG).destroy }

    it "does nothing without raising errors" do
      expect { award }.not_to change(BadgeAchievement, :count)
    end

    it "returns nil" do
      expect(award).to be_nil
    end
  end
end
