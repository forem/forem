require "rails_helper"

RSpec.describe BadgeRewarder, type: :labor do
  describe "::award_yearly_club_badges" do
    before do
      create(:badge, title: "one-year-club")
      create(:badge, title: "two-year-club")
      create(:badge, title: "three-year-club")
      create(:badge, title: "heysddssdhey")
    end

    it "rewards birthday badge to birthday folks who registered a year ago" do
      user = create(:user, created_at: 366.days.ago)
      newer_user = create(:user, created_at: 6.days.ago)
      older_user = create(:user, created_at: 390.days.ago)
      described_class.award_yearly_club_badges
      expect(user.badge_achievements.size).to eq(1)
      expect(newer_user.badge_achievements.size).to eq(0)
      expect(older_user.badge_achievements.size).to eq(0)
    end

    it "rewards 2-year birthday badge to birthday folks who registered 2 years ago" do
      user = create(:user, created_at: 731.days.ago)
      newer_user = create(:user, created_at: 6.days.ago)
      older_user = create(:user, created_at: 800.days.ago)
      described_class.award_yearly_club_badges
      expect(user.badge_achievements.size).to eq(1)
      expect(newer_user.badge_achievements.size).to eq(0)
      expect(older_user.badge_achievements.size).to eq(0)
    end

    it "rewards 3-year birthday badge to birthday folks who registered 3 years ago" do
      user = create(:user, created_at: 1096.days.ago)
      newer_user = create(:user, created_at: 6.days.ago)
      older_user = create(:user, created_at: 1200.days.ago)
      described_class.award_yearly_club_badges
      expect(user.badge_achievements.size).to eq(1)
      expect(newer_user.badge_achievements.size).to eq(0)
      expect(older_user.badge_achievements.size).to eq(0)
    end
  end

  describe "::award_beloved_comments" do
    it "rewards beloved comment to folks who have a qualifying comment" do
      create(:badge, title: "Beloved comment", slug: "beloved-comment")
      comment = create(:comment, commentable: create(:article))
      comment.update(positive_reactions_count: 30)
      described_class.award_beloved_comment_badges
      expect(BadgeAchievement.count).to eq(1)
    end

    it "does not reward beloved comment to non-qualifying comment" do
      create(:badge, title: "Beloved comment", slug: "beloved-comment")
      create(:comment, commentable: create(:article))
      described_class.award_beloved_comment_badges
      expect(BadgeAchievement.count).to eq(0)
    end
  end

  it "rewards top seven badge to users" do
    badge = create(:badge, title: "Top 7")
    user = create(:user)
    user_other = create(:user)
    described_class.award_top_seven_badges([user.username, user_other.username])
    expect(BadgeAchievement.where(badge_id: badge.id).size).to eq(2)
  end

  it "rewards fab five badge to users" do
    badge = create(:badge, title: "Fab 5")
    user = create(:user)
    user_other = create(:user)
    described_class.award_fab_five_badges([user.username, user_other.username])
    expect(BadgeAchievement.where(badge_id: badge.id).size).to eq(2)
  end

  it "rewards contributor badges" do
    badge = create(:badge, title: "Dev Contributor")
    user = create(:user)
    user_other = create(:user)
    described_class.award_contributor_badges([user.username, user_other.username])
    expect(BadgeAchievement.where(badge_id: badge.id).size).to eq(2)
  end

  describe "::award_streak_badge" do
    it "rewards badge to users with four straight weeks of articles" do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak")
      user = create(:user)
      create(:article, user: user, published: true, published_at: 26.days.ago)
      create(:article, user: user, published: true, published_at: 19.days.ago)
      create(:article, user: user, published: true, published_at: 12.days.ago)
      create(:article, user: user, published: true, published_at: 5.days.ago)
      described_class.award_streak_badge(4)
      expect(user.badges.size).to eq(1)
    end

    it "does not reward the badge to not qualified users" do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak")
      user = create(:user)
      create(:article, user: user, published: true, published_at: 26.days.ago)
      create(:article, user: user, published: true, published_at: 19.days.ago)
      create(:article, user: user, published: true, published_at: 5.days.ago)
      described_class.award_streak_badge(4)
      expect(user.badges.size).to eq(0)
    end
  end

  describe "::award_contributor_badges_from_github" do
    let(:my_ocktokit_client) { instance_double(Octokit::Client) }
    let(:user) { create(:user, :with_identity, identities: ["github"]) }

    let(:stubbed_github_commit) do
      [OpenStruct.new(author: OpenStruct.new(id: user.identities.first.uid))]
    end

    before do
      allow(Octokit::Client).to receive(:new).and_return(my_ocktokit_client)
      allow(my_ocktokit_client).to receive(:commits).and_return(stubbed_github_commit)
      create(:badge, title: "DEV Contributor")
    end

    it "award contributor badge" do
      described_class.award_contributor_badges_from_github
      expect(user.badge_achievements.size).to eq(1)
    end
  end

  describe "::award_tag_badges" do
    let(:user) { create(:user) }
    let(:second_user) { create(:user) }
    let(:third_user) { create(:user) }
    let(:article) { create(:article, user_id: user.id) }
    let(:second_article) { create(:article, user_id: second_user.id) }
    let(:third_article) { create(:article, user_id: third_user.id) }
    let(:badge) { create(:badge) }
    let(:tag) { create(:tag, badge_id: badge.id) }

    it "awards badge if qualifying article by score and tagged appropriately" do
      article.update_columns(cached_tag_list: tag.name, score: 101)
      described_class.award_tag_badges
      expect(user.badge_achievements.size).to eq(1)
      expect(user.badge_achievements.last.badge_id).to eq(badge.id)
    end

    it "renders html for message" do
      article.update_columns(cached_tag_list: tag.name, score: 101)
      described_class.award_tag_badges
      expect(user.badge_achievements.size).to eq(1)
      expect(user.badge_achievements.last.rewarding_context_message).to include("<a ")
      expect(user.badge_achievements.last.rewarding_context_message).to include(ApplicationConfig["APP_DOMAIN"])
      expect(user.badge_achievements.last.rewarding_context_message).to include(article.title)
      expect(user.badge_achievements.last.rewarding_context_message).to include(article.path)
    end

    it "does not award badge if qualifying article by score but not tagged appropriately" do
      article.update_columns(cached_tag_list: "differenttag", score: 101)
      described_class.award_tag_badges
      expect(user.badge_achievements.size).to eq(0)
    end

    it "does not award badge if qualifying article by score but not from past week" do
      article.update_columns(published_at: 8.days.ago, cached_tag_list: tag.name, score: 333)
      described_class.award_tag_badges
      expect(user.badge_achievements.size).to eq(0)
    end

    it "does not award badge if tagged appropriately but not published" do
      article.update_columns(cached_tag_list: tag.name, score: 101, published: false)
      described_class.award_tag_badges
      expect(user.badge_achievements.size).to eq(0)
    end

    it "does not award badge to user who has previously won" do
      article.update_columns(cached_tag_list: tag.name, score: 201)
      second_article.update_columns(cached_tag_list: tag.name, score: 150)
      third_article.update_columns(cached_tag_list: tag.name, score: 120)
      described_class.award_tag_badges
      expect(user.reload.badge_achievements.size).to eq(1)
      expect(second_user.reload.badge_achievements.size).to eq(0)
      described_class.award_tag_badges
      expect(user.reload.badge_achievements.size).to eq(1)
      expect(second_user.reload.badge_achievements.size).to eq(1)
      expect(third_user.reload.badge_achievements.size).to eq(0)
      described_class.award_tag_badges
      expect(user.reload.badge_achievements.size).to eq(1)
      expect(second_user.reload.badge_achievements.size).to eq(1)
      expect(third_user.reload.badge_achievements.size).to eq(1)
    end
  end

  describe "::award_badges" do
    let!(:badge) { create(:badge, title: "one-year-club") }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }

    it "awards badges" do
      expect do
        described_class.award_badges([user.username, user2.username], "one-year-club", "Congrats on a badge!")
      end.to change(BadgeAchievement, :count).by(2)
    end

    it "creates correct badge acheivements" do
      described_class.award_badges([user.username, user2.username], "one-year-club", "Congrats on a badge!")
      expect(user.badge_achievements.pluck(:badge_id)).to eq([badge.id])
      expect(user2.badge_achievements.pluck(:rewarding_context_message_markdown)).to eq(["Congrats on a badge!"])
    end
  end
end
