module Moderator
  class ManageActivityAndRoles
    attr_reader :user, :admin, :user_params

    def initialize(user:, admin:, user_params:)
      @user = user
      @admin = admin
      @user_params = user_params
    end

    def self.handle_user_roles(admin:, user:, user_params:)
      new(user: user, admin: admin, user_params: user_params).update_roles
    end

    def delete_comments
      return unless user.comments.any?

      cachebuster = CacheBuster.new
      user.comments.find_each do |comment|
        comment.reactions.delete_all
        cachebuster.bust_comment(comment.commentable)
        comment.delete
        comment.remove_notifications
      end
      cachebuster.bust_user(user)
    end

    def delete_articles
      return unless user.articles.any?

      cachebuster = CacheBuster.new
      virtual_articles = user.articles.map { |article| Article.new(article.attributes) }
      user.articles.find_each do |article|
        article.reactions.delete_all
        article.comments.includes(:user).find_each do |comment|
          comment.reactions.delete_all
          cachebuster.bust_comment(comment.commentable)
          cachebuster.bust_user(comment.user)
          comment.delete
        end
        article.remove_algolia_index
        article.delete
        article.purge
      end
      virtual_articles.each do |article|
        cachebuster.bust_article(article)
      end
    end

    def delete_user_activity
      user.notifications.delete_all
      user.reactions.delete_all
      user.follows.delete_all
      Follow.where(followable_id: user.id, followable_type: "User").delete_all
      user.messages.delete_all
      user.chat_channel_memberships.delete_all
      user.mentions.delete_all
      user.badge_achievements.delete_all
      user.github_repos.delete_all
    end

    def remove_privileges
      @user.remove_role :video_permission
      @user.remove_role :workshop_pass
      @user.remove_role :pro
      remove_mod_roles
      remove_tag_moderator_role
    end

    def remove_mod_roles
      @user.remove_role :trusted
      @user.remove_role :tag_moderator
      @user.update(email_tag_mod_newsletter: false)
      MailchimpBot.new(user).manage_tag_moderator_list
      @user.update(email_community_mod_newsletter: false)
      MailchimpBot.new(user).manage_community_moderator_list
    end

    def remove_tag_moderator_role
      @user.remove_role :tag_moderator
      MailchimpBot.new(user).manage_tag_moderator_list
    end

    def create_note(reason, content)
      Note.create(
        author_id: @admin.id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: reason,
        content: content,
      )
    end

    def handle_user_status(role, note)
      case role
      when "Ban" || "Spammer"
        user.add_role :banned
        remove_privileges
      when "Warn"
        warned
      when "Comment Ban"
        comment_banned
      when "Regular Member"
        regular_member
      when "Trusted"
        remove_negative_roles
        user.remove_role :pro
        add_trusted_role
      when "Pro"
        remove_negative_roles
        add_trusted_role
        user.add_role :pro
      end
      create_note(role, note)
    end

    def comment_banned
      user.add_role :comment_banned
      user.remove_role :banned
      remove_privileges
    end

    def regular_member
      remove_negative_roles
      user.remove_role :pro
      remove_mod_roles
    end

    def warned
      user.add_role :warned
      user.remove_role :banned
      remove_privileges
    end

    def add_trusted_role
      return if user.has_role?(:trusted)

      user.add_role :trusted
      user.update(email_community_mod_newsletter: true)
      NotifyMailer.trusted_role_email(user).deliver
      MailchimpBot.new(user).manage_community_moderator_list
    end

    def remove_negative_roles
      user.remove_role :banned if user.banned
      user.remove_role :warned if user.warned
      user.remove_role :comment_banned if user.comment_banned
    end

    def update_trusted_cache
      RedisRailsCache.delete("user-#{@user.id}/has_trusted_role")
      @user.trusted
    end

    def update_roles
      handle_user_status(user_params[:user_status], user_params[:note_for_current_role])
      update_trusted_cache
    end
  end
end
