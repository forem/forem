module Moderator
  class ManageActivityAndRoles
    attr_reader :user, :admin, :user_params

    def self.handle_user_roles(admin:, user:, user_params:)
      new(user: user, admin: admin, user_params: user_params).update_roles
    end

    def initialize(user:, admin:, user_params:)
      @user = user
      @admin = admin
      @user_params = user_params
    end

    def delete_comments
      Users::DeleteComments.call(user)
    end

    def delete_articles
      Users::DeleteArticles.call(user)
    end

    def delete_user_activity
      Users::DeleteActivity.call(user)
    end

    def delete_user_podcasts
      Users::DeletePodcasts.call(user)
    end

    def remove_privileges
      remove_mod_roles
      remove_tag_moderator_role
    end

    def remove_notifications
      Notifications::RemoveBySpammerWorker.perform_async(user.id)
    end

    def remove_mod_roles
      @user.remove_role(:trusted)
      @user.remove_role(:tag_moderator)
      @user.notification_setting.update(email_tag_mod_newsletter: false)
      Mailchimp::Bot.new(user).manage_tag_moderator_list
      @user.notification_setting.update(email_community_mod_newsletter: false)
      Mailchimp::Bot.new(user).manage_community_moderator_list
    end

    def remove_tag_moderator_role
      @user.remove_role(:tag_moderator)
      Mailchimp::Bot.new(user).manage_tag_moderator_list
    end

    def create_note(reason, content)
      Note.create(
        author_id: @admin.id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: reason,
        content: content || "#{@admin.username} updated #{@user.username}",
      )
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def handle_user_status(role, note)
      case role
      when "Admin"
        assign_elevated_role_to_user(user, :admin)
        TagModerators::AddTrustedRole.call(user)
      when "Comment Suspended"
        comment_suspended
      when "Limited"
        limited
      when "Suspended" || "Spammer"
        user.add_role(:suspended)
        remove_privileges
      when "Spam"
        user.add_role(:spam)
        remove_privileges
        remove_notifications
        resolve_spam_reports
        confirm_flag_reactions
        user.profile.touch
      when "Super Moderator"
        assign_elevated_role_to_user(user, :super_moderator)
        TagModerators::AddTrustedRole.call(user)
      when "Good standing"
        regular_member
      when /^(Resource Admin: )/
        check_super_admin
        remove_negative_roles
        user.add_role(:single_resource_admin, role.split("Resource Admin: ").last.safe_constantize)
      when "Super Admin"
        assign_elevated_role_to_user(user, :super_admin)
        TagModerators::AddTrustedRole.call(user)
      when "Tech Admin"
        assign_elevated_role_to_user(user, :tech_admin)
        # DataUpdateScripts falls under the admin namespace
        # and hence requires a single_resource_admin role to view
        # this technical admin resource
        user.add_role(:single_resource_admin, DataUpdateScript)
      when "Trusted"
        remove_negative_roles
        TagModerators::AddTrustedRole.call(user)
      when "Warned"
        warned
      when "Base Subscriber"
        base_subscriber
      end
      create_note(role, note)

      user.articles.published.find_each(&:async_score_calc)
      user.comments.find_each(&:calculate_score)
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def assign_elevated_role_to_user(user, role)
      check_super_admin
      remove_negative_roles
      user.add_role(role)

      # Clear cache key if the elevated role matches Rack::Attack bypass roles
      return unless Rack::Attack::ADMIN_ROLES.include?(role.to_s)

      Rails.cache.delete(Rack::Attack::ADMIN_API_CACHE_KEY)
    end

    def check_super_admin
      raise I18n.t("services.moderator.manage_activity_and_roles.need_super") unless @admin.super_admin?
    end

    def comment_suspended
      user.add_role(:comment_suspended)
      user.remove_role(:suspended)
      remove_privileges
    end

    def limited
      user.add_role(:limited)
      remove_privileges
    end

    def regular_member
      remove_negative_roles
      remove_mod_roles
    end

    def warned
      user.add_role(:warned)
      user.remove_role(:suspended) if user.suspended?
      user.remove_role(:spam) if user.spam?
      remove_privileges
    end

    def base_subscriber
      user.add_role(:base_subscriber)
      user.touch
      user.profile&.touch
      NotifyMailer.with(user: user).base_subscriber_role_email.deliver_now
    end

    def remove_negative_roles
      user.remove_role(:limited) if user.limited?
      user.remove_role(:suspended) if user.suspended?
      user.remove_role(:spam) if user.spam?
      user.remove_role(:warned) if user.warned?
      user.remove_role(:comment_suspended) if user.comment_suspended?
    end

    def update_roles
      handle_user_status(user_params[:user_status], user_params[:note_for_current_role])
    end

    private

    def resolve_spam_reports
      Users::ResolveSpamReportsWorker.perform_async(user.id)
    end

    def confirm_flag_reactions
      Users::ConfirmFlagReactionsWorker.perform_async(user.id)
    end
  end
end
