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
      raise "You cannot merge the same two user id#s" if @delete_user.id == @keep_user.id

      handle_identities
      merge_content
      merge_follows
      merge_chat_mentions
      merge_profile
      remove_additional_email
      update_social
      @delete_user.delete
    end

    private

    def handle_identities
      raise "The user being deleted already has two identities. Are you sure this is the right user to be deleted? If so, a super admin will need to do this from the console to be safe." if @delete_user.identities.count > 1

      return true if @keep_user.identities.count > 1 || @delete_user.identities.none? || @keep_user.identities.last.provider == @delete_user.identities.last.provider

      @delete_user.identities.first.update(user_id: @keep_user.id)
    end

    def update_social
      @old_tu = @delete_user.twitter_username
      @old_gu = @delete_user.github_username
      @delete_user.update_columns(twitter_username: nil, github_username: nil)
      @keep_user.update_columns(twitter_username: @old_tu) if @keep_user.twitter_username.nil?
      @keep_user.update_columns(github_username: @old_gu) if @keep_user.github_username.nil?
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
      @delete_user.badge_achievements.update_all(user_id: @keep_user.id) if @delete_user.badge_achievements.any?
    end

    def merge_chat_mentions
      @delete_user.chat_channel_memberships.update_all(user_id: @keep_user.id) if @delete_user.chat_channel_memberships.any?
      @delete_user.mentions.update_all(user_id: @keep_user.id) if @delete_user.mentions.any?
    end

    def merge_follows
      @delete_user.follows&.update_all(follower_id: @keep_user.id) if @delete_user.follows.any?
      @delete_user_followers = Follow.where(followable_id: @delete_user.id, followable_type: "User")
      @delete_user_followers.update_all(followable_id: @keep_user.id) if @delete_user_followers.any?
    end

    def merge_content
      @delete_user.reactions.update_all(user_id: @keep_user.id) if @delete_user.reactions.any?
      @delete_user.comments.update_all(user_id: @keep_user.id) if @delete_user.comments.any?
      @delete_user.articles.update_all(user_id: @keep_user.id) if @delete_user.articles.any?
    end
  end
end
