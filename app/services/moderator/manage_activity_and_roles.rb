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

      user.comments.find_each do |comment|
        comment.reactions.delete_all
        CacheBuster.new.bust_comment(comment.commentable, user.username)
        comment.delete
        comment.remove_notifications
      end
    end

    def delete_articles
      return unless user.articles.any?

      user.articles.find_each do |article|
        article.reactions.delete_all
        article.comments.find_each do |comment|
          comment.reactions.delete_all
          CacheBuster.new.bust_comment(comment.commentable, comment.user.username)
          comment.delete
        end
        CacheBuster.new.bust_article(article)
        article.remove_algolia_index
        article.delete
      end
    end

    def delete_user_activity
      user.notifications.delete_all
      user.reactions.delete_all
      user.follows.delete_all
      Follow.where(followable_id: user.id, followable_type: "User").delete_all
      user.chat_channel_memberships.delete_all
      user.mentions.delete_all
      user.badge_achievements.delete_all
      user.github_repos.delete_all
      delete_comments
      delete_articles
    end

    def remove_privileges
      @user.remove_role :trusted
      @user.remove_role :video_permission
      @user.remove_role :tag_moderator
      @user.remove_role :workshop_pass
      @user.remove_role :pro
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
        user.add_role :warned
        user.remove_role :banned
        remove_privileges
      when "Comment Ban"
        user.add_role :comment_banned
        user.remove_role :banned
        remove_privileges
      when "Regular Member"
        remove_negative_roles
        user.remove_role :pro
      when "Trusted"
        remove_negative_roles
        user.remove_role :pro
        user.add_role :trusted
      when "Pro"
        remove_negative_roles
        user.add_role :trusted
        user.add_role :pro
      end
      create_note(role, note)
    end

    def remove_negative_roles
      user.remove_role :banned if user.banned
      user.remove_role :warned if user.warned
      user.remove_role :comment_banned if user.comment_banned
    end

    def deactivate_mentorship(relationships)
      relationships.each do |relationship|
        relationship.update(active: false)
      end
    end

    def inactive_mentorship(mentor, mentee)
      relationship = MentorRelationship.where(mentor_id: mentor.id, mentee_id: mentee.id)
      relationship.update(active: false)
    end

    def update_mentorship_status
      if user_params[:toggle_mentorship] == "1"
        @user.add_role :banned_from_mentorship
        mentee_relationships = MentorRelationship.where(mentor_id: @user.id)
        mentor_relationships = MentorRelationship.where(mentee_id: @user.id)
        deactivate_mentorship(mentee_relationships)
        deactivate_mentorship(mentor_relationships)
        @user.update(offering_mentorship: false, seeking_mentorship: false)
        create_note("banned_from_mentorship", user_params[:mentorship_note])
      else
        @user.remove_role :banned_from_mentorship
        create_note("reinstate_mentorship_privileges", user_params[:mentorship_note])
      end
    end

    def update_trusted_cache
      Rails.cache.delete("user-#{@user.id}/has_trusted_role")
      @user.trusted
    end

    def update_roles
      if user_params[:toggle_mentorship]
        update_mentorship_status
      else
        handle_user_status(user_params[:user_status], user_params[:note_for_current_role])
        update_trusted_cache
      end
    end
  end
end
