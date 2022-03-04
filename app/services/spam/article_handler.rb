module Spam
  module ArticleHandler
    # Test the article for spamminess.  If it's not spammy, don't do anything.
    #
    # If it is spammy, escalate the situation!
    #
    # @param article [Article] the article to check for spamminess
    # @param attributes [Array<Symbol>] test these attributes of the article.
    #
    # @note We are not blocking the spammer from submitting the
    # article with spam content, but we are instead performing some
    # administrative tasks to indicate that we're taking notice and
    # even escalating.
    def self.handle!(article:, attributes: %i[title body_markdown])
      return :not_spam if attributes.none? do |attr|
                            Settings::RateLimit.trigger_spam_for?(text: article.public_send(attr))
                          end

      Reaction.create!(
        user_id: Settings::General.mascot_user_id,
        reactable_id: article.id,
        reactable_type: "Article",
        category: "vomit",
      )

      return unless Reaction.user_has_been_given_too_many_spammy_reactions?(user: article.user)

      # TODO: What should we do with their active session?  I think we
      # might want to explore later raising an exception that the
      # controller rescues and logs the user out.  Because, as written
      # they might still be logged in but have limited abilities.
      article.user.add_role(:suspended)

      Note.create(
        author_id: Settings::General.mascot_user_id,
        noteable: article.user,
        reason: "automatic_suspend",
        content: I18n.t("services.spam.article_handler.suspended_too_many"),
      )
    end
  end
end
