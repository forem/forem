module Moderator
  class MergeUser < ManageActivityAndRoles
    def self.call(admin:, keep_user:, delete_user_id:)
      new(keep_user: keep_user, admin: admin, delete_user_id: delete_user_id).merge
    end

    attr_reader :keep_user, :admin, :delete_user_id

    def initialize(admin:, keep_user:, delete_user_id:) # rubocop:disable Lint/MissingSuper
      @keep_user = keep_user
      @admin = admin
      @delete_user = User.find(delete_user_id.to_i)
    end

    def merge
      raise "You cannot merge the same two user ID#s" if @delete_user.id == @keep_user.id

      handle_identities
      merge_reactions
      merge_comments_and_mentions
      merge_articles
      merge_follows
      merge_chat_channels
      merge_sponsorships
      merge_profile
      merge_badge_achievements
      update_social
      Users::DeleteWorker.new.perform(@delete_user.id, true)
      @keep_user.touch(:profile_updated_at)
      Users::MergeSyncWorker.perform_async(@keep_user.id)

      EdgeCache::Bust.call("/#{@keep_user.username}")
    end

    private

    def handle_identities
      error_message = "The user being deleted already has two or more identities. " \
        "Are you sure this is the right user to be deleted? " \
        "If so, a super admin will need to do this from the console to be safe."
      raise error_message if @delete_user.identities.count >= 2

      return true if
        @keep_user.identities.count.positive? ||
          @delete_user.identities.none? ||
          @keep_user.identities.last.provider == @delete_user.identities.last.provider

      @delete_user.identities.first.update_columns(user_id: @keep_user.id)
    end

    def update_social
      @old_tu = @delete_user.twitter_username
      @old_gu = @delete_user.github_username
      ActiveRecord::Base.transaction do
        @delete_user.update_columns(twitter_username: nil, github_username: nil)
        @keep_user.update_columns(twitter_username: @old_tu) if @keep_user.twitter_username.nil?
        @keep_user.update_columns(github_username: @old_gu) if @keep_user.github_username.nil?
        @keep_user.touch(:profile_updated_at, :last_followed_at) # clears cache on sidebar
      end
    end

    def merge_sponsorships
      @delete_user.sponsorships.update_all(user_id: @keep_user.id)
    end

    def merge_profile
      @delete_user.github_repos.update_all(user_id: @keep_user.id)
      @keep_user.touch(:github_repos_updated_at)

      @keep_user.update_columns(created_at: @delete_user.created_at) if @delete_user.created_at < @keep_user.created_at
    end

    def merge_badge_achievements
      duplicate_badges = @delete_user.badge_achievements.pluck(:badge_id).intersection(
        @keep_user.badge_achievements.pluck(:badge_id),
      )
      @delete_user.badge_achievements.where(badge_id: duplicate_badges).delete_all
      @delete_user.badge_achievements.update_all(user_id: @keep_user.id)
      BadgeAchievement.counter_culture_fix_counts(where: { users: { id: @keep_user.id } })
    end

    def merge_chat_channels
      duplicate_moderator_memberships = @delete_user.chat_channel_memberships.where(
        status: "active", role: "mod",
      ).pluck(:chat_channel_id).intersection(
        @keep_user.chat_channel_memberships.where(
          status: "active", role: "mod",
        ).pluck(:chat_channel_id),
      )
      @delete_user.chat_channel_memberships.where(chat_channel_id: duplicate_moderator_memberships).delete_all

      moderator_memberships = @delete_user.chat_channel_memberships.where(
        status: "active", role: "mod",
      ).pluck(:chat_channel_id)

      duplicate_memberships = @delete_user.chat_channel_memberships.where(
        status: "active",
      ).pluck(:chat_channel_id).intersection(
        @keep_user.chat_channel_memberships.where(status: "active").pluck(:chat_channel_id),
      )
      @delete_user.chat_channel_memberships.where(chat_channel_id: duplicate_memberships).delete_all
      @keep_user.chat_channel_memberships.where(chat_channel_id: moderator_memberships).update_all(role: "mod")
      @delete_user.chat_channel_memberships.update_all(user_id: @keep_user.id)
    end

    def merge_follows
      duplicate_followers = Follow.where(followable: @delete_user).pluck(:follower_id, :follower_type).intersection(
        Follow.where(followable: @keep_user).pluck(:follower_id, :follower_type),
      )
      Follow.where(follower: duplicate_followers, followable: @delete_user).delete_all
      Follow.where(followable: @delete_user).update_all(followable_id: @keep_user.id)

      duplicate_followables = Follow.where(follower: @delete_user).pluck(:followable_id, :followable_type).intersection(
        Follow.where(follower: @keep_user).pluck(:followable_id, :followable_type),
      )
      Follow.where(followable: duplicate_followables, follower: @delete_user).delete_all
      Follow.where(follower: @delete_user).update_all(follower_id: @keep_user.id)
    end

    def merge_reactions
      duplicate_reactions = @delete_user.reactions.pluck(:category, :reactable_type, :reactable_id).intersection(
        @keep_user.reactions.pluck(:category, :reactable_type, :reactable_id),
      )
      @delete_user.reactions.where(category: duplicate_reactions, reactable: duplicate_reactions).delete_all
      @delete_user.reactions.update_all(user_id: @keep_user.id)
      @keep_user.reactions_count = @keep_user.reactions.size
    end

    def merge_comments_and_mentions
      @delete_user.comments.update_all(user_id: @keep_user.id)
      @keep_user.comments_count = @keep_user.comments.size
      @delete_user.mentions.update_all(user_id: @keep_user.id)
    end

    def merge_articles
      @delete_user.articles.update_all(user_id: @keep_user.id)
      @keep_user.articles_count = @keep_user.articles.size
    end
  end
end
