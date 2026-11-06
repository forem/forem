require "rails_helper"

RSpec.describe Badges::AwardCommunityFavorite, type: :service do
  subject(:award) { described_class.call(favoritable: article, favoriter: leader) }

  let(:leader) { create(:user, :without_profile, :community_leader_level_1, profile_image: nil) }
  let(:author) { create(:user, :without_profile, profile_image: nil) }
  let(:article) do
    create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current,
                     with_tags: false, with_main_image: false)
  end

  def create_milestone_badge(milestone)
    create(:badge,
           title: "Community Favorite - #{milestone} Gems",
           allow_multiple_awards: false)
  end

  def insert_favorited_articles(count)
    now = Time.current
    Article.insert_all!(
      Array.new(count) do
        {
          user_id: author.id,
          favorited_by_user_id: leader.id,
          favorited_at: now,
          created_at: now,
          updated_at: now
        }
      end,
    )
  end

  context "when author receives their 1st gem" do
    it "sends an in-app progress notification to the author without awarding a badge", :aggregate_failures do
      expect { award }.to change(Notification, :count).by(1)
        .and not_change(BadgeAchievement, :count)

      notification = Notification.last
      expect(notification.user_id).to eq(author.id)
      expect(notification.action).to eq("Favorited")
      expect(notification.json_data["message"]).to include("If you get two gems")
      expect(notification.json_data["message"]).to include(URL.article(article))
    end

    it "sends progress notification when a comment is favorited", :aggregate_failures do
      article.update_columns(favorited_by_user_id: nil, favorited_at: nil)
      comment = create(:comment, commentable: article, user: author,
                                 favorited_by_user_id: leader.id, favorited_at: Time.current)

      expect { described_class.call(favoritable: comment, favoriter: leader) }
        .to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user_id).to eq(author.id)
      expect(notification.json_data["message"]).to include(URL.comment(comment))
    end
  end

  context "when author reaches the 2 gems milestone" do
    before do
      create_milestone_badge(2)
      insert_favorited_articles(1)
    end

    it "awards the 2 Gems milestone badge", :aggregate_failures do
      expect { award }.to change(BadgeAchievement, :count).by(1)

      achievement = BadgeAchievement.last
      expect(achievement.user_id).to eq(author.id)
      expect(achievement.badge.slug).to eq("community-favorite-2-gems")
      expect(achievement.rewarder_id).to eq(leader.id)
      expect(achievement.rewarding_context_message_markdown).to include("2 Gems badge")
      expect(achievement.rewarding_context_message_markdown).to include("4 times")
      expect(achievement.rewarding_context_message_markdown).to include("[#{article.title}](#{URL.article(article)})")
    end
  end

  context "when author receives intermediate non-milestone gems (e.g. 3 gems)" do
    before do
      insert_favorited_articles(2)
    end

    it "sends an in-app progress notification for next milestone at 4 without awarding a badge", :aggregate_failures do
      expect { award }.to change(Notification, :count).by(1)
        .and not_change(BadgeAchievement, :count)

      notification = Notification.last
      expect(notification.user_id).to eq(author.id)
      expect(notification.action).to eq("Favorited")
      expect(notification.json_data["message"]).to include("3 times")
      expect(notification.json_data["message"]).to include("4 times")
    end
  end

  context "when author reaches subsequent milestones (4, 8, 16, 32, 64)" do
    it "awards each milestone badge with copy indicating the next milestone or highest milestone",
       :aggregate_failures do
      [4, 8, 16, 32, 64].each { |milestone| create_milestone_badge(milestone) }

      [
        [3, "community-favorite-4-gems", "4 Gems badge", "8 times"],
        [4, "community-favorite-8-gems", "8 Gems badge", "16 times"],
        [8, "community-favorite-16-gems", "16 Gems badge", "32 times"],
        [16, "community-favorite-32-gems", "32 Gems badge", "64 times"],
        [32, "community-favorite-64-gems", "64 Gems badge", "highest milestone"],
      ].each do |additional_gems, expected_slug, expected_badge_text, expected_next_text|
        insert_favorited_articles(additional_gems)

        described_class.call(favoritable: article, favoriter: leader)
        achievement = BadgeAchievement.order(:id).last
        expect(achievement.badge.slug).to eq(expected_slug)
        expect(achievement.rewarding_context_message_markdown).to include(expected_badge_text)
        expect(achievement.rewarding_context_message_markdown).to include(expected_next_text)
      end
    end

    it "awards milestone badge when reaching milestone via comment favorite", :aggregate_failures do
      create_milestone_badge(2)
      comment = create(:comment, commentable: article, user: author,
                                 favorited_by_user_id: leader.id, favorited_at: Time.current)

      described_class.call(favoritable: comment, favoriter: leader)

      achievement = BadgeAchievement.last
      expect(achievement.badge.slug).to eq("community-favorite-2-gems")
      link_markdown = "[#{comment.commentable.title}](#{URL.comment(comment)})"
      expect(achievement.rewarding_context_message_markdown).to include(link_markdown)
    end
  end

  context "when badge has fallback slug without -gems (e.g. community-favorite-2)" do
    before do
      create(:badge, title: "Community Favorite 2", slug: "community-favorite-2")
      insert_favorited_articles(1)
    end

    it "finds and awards the badge using fallback slug", :aggregate_failures do
      expect { award }.to change(BadgeAchievement, :count).by(1)
      expect(BadgeAchievement.last.badge.slug).to eq("community-favorite-2")
    end
  end

  context "when the badge record does not exist in the database" do
    before do
      # 1 existing favorited post so this would be milestone 2
      insert_favorited_articles(1)
    end

    it "returns nil and does not award a badge without raising errors", :aggregate_failures do
      expect { expect(award).to be_nil }.not_to change(BadgeAchievement, :count)
    end
  end
end
