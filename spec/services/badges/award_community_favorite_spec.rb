require "rails_helper"

RSpec.describe Badges::AwardCommunityFavorite, type: :service do
  subject(:award) { described_class.call(favoritable: article, favoriter: leader) }

  let(:leader) { create(:user, :community_leader_level_1) }
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current) }

  before do
    described_class::MILESTONES.each do |milestone|
      create(:badge,
             title: "Community Favorite - #{milestone} Gems",
             allow_multiple_awards: false)
    end
  end

  context "when author receives their 1st gem" do
    it "does not award a BadgeAchievement" do
      expect { award }.not_to change(BadgeAchievement, :count)
    end

    it "sends an in-app progress notification to the author" do
      expect { award }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user_id).to eq(author.id)
      expect(notification.action).to eq("Favorited")
      expect(notification.json_data["message"]).to include("If you get two gems")
      expect(notification.json_data["message"]).to include(URL.article(article))
    end

    it "sends progress notification when a comment is favorited" do
      comment = create(:comment, commentable: create(:article), user: author,
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
      # 1 existing favorited post
      create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current)
    end

    it "awards the 2 Gems milestone badge" do
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
      # 2 existing favorited posts (milestone 2 already reached)
      2.times { create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current) }
    end

    it "does not award a new BadgeAchievement" do
      expect { award }.not_to change(BadgeAchievement, :count)
    end

    it "sends an in-app progress notification informing them of next milestone at 4" do
      expect { award }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user_id).to eq(author.id)
      expect(notification.action).to eq("Favorited")
      expect(notification.json_data["message"]).to include("3 times")
      expect(notification.json_data["message"]).to include("4 times")
    end
  end

  context "when author reaches subsequent milestones (4, 8, 16, 32, 64)" do
    it "awards 4 gems badge with copy indicating next is 8" do
      3.times { create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current) }

      award
      achievement = BadgeAchievement.last
      expect(achievement.badge.slug).to eq("community-favorite-4-gems")
      expect(achievement.rewarding_context_message_markdown).to include("4 Gems badge")
      expect(achievement.rewarding_context_message_markdown).to include("8 times")
    end

    it "awards 8 gems badge with copy indicating next is 16" do
      7.times { create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current) }

      award
      achievement = BadgeAchievement.last
      expect(achievement.badge.slug).to eq("community-favorite-8-gems")
      expect(achievement.rewarding_context_message_markdown).to include("8 Gems badge")
      expect(achievement.rewarding_context_message_markdown).to include("16 times")
    end

    it "awards 16 gems badge with copy indicating next is 32" do
      15.times { create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current) }

      award
      achievement = BadgeAchievement.last
      expect(achievement.badge.slug).to eq("community-favorite-16-gems")
      expect(achievement.rewarding_context_message_markdown).to include("16 Gems badge")
      expect(achievement.rewarding_context_message_markdown).to include("32 times")
    end

    it "awards 32 gems badge with copy indicating next is 64" do
      31.times { create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current) }

      award
      achievement = BadgeAchievement.last
      expect(achievement.badge.slug).to eq("community-favorite-32-gems")
      expect(achievement.rewarding_context_message_markdown).to include("32 Gems badge")
      expect(achievement.rewarding_context_message_markdown).to include("64 times")
    end

    it "awards 64 gems badge with copy celebrating highest milestone" do
      63.times { create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current) }

      award
      achievement = BadgeAchievement.last
      expect(achievement.badge.slug).to eq("community-favorite-64-gems")
      expect(achievement.rewarding_context_message_markdown).to include("64 Gems badge")
      expect(achievement.rewarding_context_message_markdown).to include("highest milestone")
    end

    it "awards milestone badge when reaching milestone via comment favorite" do
      create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current)
      comment = create(:comment, commentable: create(:article), user: author,
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
      Badge.destroy_all
      create(:badge, title: "Community Favorite 2", slug: "community-favorite-2")
      create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current)
    end

    it "finds and awards the badge using fallback slug" do
      expect { award }.to change(BadgeAchievement, :count).by(1)
      expect(BadgeAchievement.last.badge.slug).to eq("community-favorite-2")
    end
  end

  context "when the badge record does not exist in the database" do
    before do
      # 1 existing favorited post so this would be milestone 2
      create(:article, user: author, favorited_by_user_id: leader.id, favorited_at: Time.current)
      Badge.destroy_all
    end

    it "does nothing without raising errors" do
      expect { award }.not_to change(BadgeAchievement, :count)
    end

    it "returns nil" do
      expect(award).to be_nil
    end
  end
end
