# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
require "rails_helper"

RSpec.describe BadgeRewarder do
  it "rewards birthday badge to birthday folks who registered a year ago" do
    user = create(:user, created_at: 366.days.ago)
    newer_user = create(:user, created_at: 6.days.ago)
    older_user = create(:user, created_at: 390.days.ago)
    create(:badge, title: "heyhey")
    create(:badge, title: "heysddssdhey")
    described_class.award_yearly_club_badges
    expect(user.badge_achievements.size).to eq(1)
    expect(newer_user.badge_achievements.size).to eq(0)
    expect(older_user.badge_achievements.size).to eq(0)
  end

  it "rewards beloved comment to folks who have a qualifying comment" do
    user = create(:user)
    user_other = create(:user)
    article = create(:article)
    create(:comment, user_id: user.id, positive_reactions_count: 30, commentable_id: article.id)
    create(
      :comment, user_id: user_other.id, positive_reactions_count: 3, commentable_id: article.id
    )
    create(:badge, title: "heweewweyhey")
    create(:badge, title: "heweweewewewewyhey")
    create(:badge, title: "heewwewewwwwwyhey")
    described_class.award_beloved_comment_badges
    expect(user.badge_achievements.size).to eq(1)
    expect(user_other.badge_achievements.size).to eq(0)
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

  describe "::award_contributor_badges_from_github" do
    let(:my_ocktokit_client) { instance_double(Octokit::Client) }
    let(:user) { create(:user) }

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
end

# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
