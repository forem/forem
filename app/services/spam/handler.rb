module Spam
  # This module is responsible for handling spam in our various user input sources.
  #
  # @note We may not immediately block spam but instead slowly escalate our response.
  module Handler
    # @return [TrueClass] if we are going to try to use more rigorous spam handling
    # @return [FalseClass] if we are using less rigorous spam handling
    def self.more_rigorous_user_profile_spam_checking?
      FeatureFlag.enabled?(:more_rigorous_user_profile_spam_checking)
    end

    # @return [TrueClass] if we are going to unpublish articles when we auto-suspend
    # @return [FalseClass] if we are not going to unpublish articles when we auto-suspend
    def self.unpublish_all_posts_when_user_auto_suspended?
      FeatureFlag.enabled?(:unpublish_all_posts_when_user_auto_suspended)
    end

    # Test the article for spamminess.  If it's not spammy, don't do anything.
    #
    # If it is spammy, escalate the situation!
    #
    # @param article [Article] the article to check for spamminess
    # @param attributes [Array<Symbol>] test these attributes of the article.
    def self.handle_article!(article:, attributes: %i[title body_markdown])
      text = attributes.map { |attr| article.public_send(attr) }.join("\n")
      return :not_spam unless Settings::RateLimit.trigger_spam_for?(text: text)

      issue_spam_reaction_for!(reactable: article)

      return unless Reaction.user_has_been_given_too_many_spammy_article_reactions?(
        user: article.user,
        include_user_profile: more_rigorous_user_profile_spam_checking?,
      )

      suspend!(user: article.user)
    end

    # Test the comment for spamminess.  If it's not spammy, don't do anything.
    #
    # If it is spammy, escalate the situation!
    #
    # @param comment [Comment] the comment to check for spamminess
    def self.handle_comment!(comment:)
      # TODO: Is this correct logic?  I was trying to reason through
      # the original logic and I think there's something off on that
      # original logic.
      #
      # I believe the intention of the past logic was that we want to
      # treat recently registered users with a bit of suspicion.
      return :not_spam unless Settings::RateLimit.user_considered_new?(user: comment&.user)
      return :not_spam unless Settings::RateLimit.trigger_spam_for?(text: comment.body_markdown)

      issue_spam_reaction_for!(reactable: comment)

      return unless Reaction.user_has_been_given_too_many_spammy_comment_reactions?(
        user: comment.user,
        include_user_profile: more_rigorous_user_profile_spam_checking?,
      )

      suspend!(user: comment.user)
    end

    # Test the user for spamminess.  If it's not spammy, don't do anything.
    #
    # If it is spammy, escalate the situation!
    #
    # @param user [User] the user to check for spamminess
    def self.handle_user!(user:)
      text = [user.name]

      if more_rigorous_user_profile_spam_checking?
        text += [
          user.email,
          user.github_username,
          user.profile&.website_url,
          user.profile&.location,
          user.profile&.summary,
          user.twitter_username,
          user.username,
        ].compact
      end

      text = text.join("\n")

      return :not_spam unless Settings::RateLimit.trigger_spam_for?(text: text)

      issue_spam_reaction_for!(reactable: user)
    end

    # Suspend the given user because of too many spammy actions.
    #
    # @param user [User]
    #
    # @todo What should we do with their active session?  I think we
    #       might want to explore later raising an exception that the
    #       controller rescues and logs the user out.  Because, as
    #       written they might still be logged in but have limited
    #       abilities.
    def self.suspend!(user:)
      # TODO: Should we send an email when we auto-suspend?  As a matter of practice, whenever we
      #       suspend someone should we notify.  Note, this is not the only place that we suspend
      #       someone.
      user.add_role(:suspended)

      Note.create(
        author_id: Settings::General.mascot_user_id,
        noteable: user,
        reason: "automatic_suspend",
        content: I18n.t("models.comment.suspended_too_many"),
      )

      return unless unpublish_all_posts_when_user_auto_suspended?

      user.articles.update_all(published: false)
    end
    private_class_method :suspend!

    # Have the mascot of this Forem react negatively to this reactable.
    #
    # @param reactable [ActiveRecord::Base]
    def self.issue_spam_reaction_for!(reactable:)
      Reaction.create(
        user_id: Settings::General.mascot_user_id,
        reactable: reactable,
        category: "vomit",
      )
    end
    private_class_method :issue_spam_reaction_for!
  end
end
