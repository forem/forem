module Moderator
  class MergeUser < ManageActivityAndRoles
    attr_reader :keep_user, :admin, :delete_user_id

    def initialize(admin:, keep_user:, delete_user_id:)
      @keep_user = keep_user
      @admin = admin
      @delete_user = User.find(delete_user_id.to_i)
    end

    def self.call_merge(admin:, keep_user:, delete_user_id:)
      new(keep_user: keep_user, admin: admin, delete_user_id: delete_user_id).merge
    end

    def merge
      merge_content
      merge_relationships
      merge_profile
      remove_additional_email
      update_social
      @delete_user.delete!
    end

    def update_social
      @old_tu = @delete_user.twitter_username
      @old_gu = @delete_user.github_username
      @delete_user.update_columns(twitter_username: nil, github_username: nil)
      @keep_user.update!(twitter_username: @old_tu) if @keep_user.twitter_username.blank?
      @keep_user.update!(github_username: @old_gu) if @keep_user.github_username.blank?
    end

    def remove_additional_email
      return if @delete_user.email.blank?

      email_attr = {
        email_comment_notifications: false,
        email_digest_periodic: false,
        email_follower_notifications: false,
        email_mention_notifications: false,
        email_newsletter: false,
        email_unread_notifications: false,
        email_badge_notifications: false,
        email_membership_newsletter: false
      }

      @delete_user.update(email_attr)
      @delete_user.unsubscribe_from_newsletters
    end

    def merge_profile
      @delete_user.github_repos&.update_all(user_id: @keep_user.id) if @delete_user.github_repos.any?
      @delete_user.badge_achievements.update_al(user_id: @keep_user.id) if @delete_user.badge_achievements.any?
    end

    def merge_relationships
      @delete_user.follows&.update_all(follower_id: @keep_user.id) if @delete_user.follows.any?
      @delete_user.chat_channel_memberships.update_all(user_id: @keep_user.id) if @delete_user.chat_channel_memberships.any?
      @delete_user.mentions.update_all(user_id: @keep_user.id) if @delete_user.mentions.any?
      @delete_user_followers = Follow.where(followable_id: @delete_user.id, followable_type: "User")
      @delete_user_followers.update_all(@keep_user.id) if @delete_user_followers.any?
    end

    def merge_content
      @delete_user.reactions.update_all(user_id: @keep_user.id) if @delete_user.reactions.any?
      @delete_user.comments.update_all(user_id: @keep_user.id) if @delete_user.comments.any?
      @delete_user.articles.update_all(user_id: @keep_user.id) if @delete_user.articles.any?
    end
  end
end
