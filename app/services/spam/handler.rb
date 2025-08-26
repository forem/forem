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
      # First, run content moderation labeling
      label_article_content!(article)

      # Handle clear and obvious violations immediately
      if %w[clear_and_obvious_spam clear_and_obvious_harmful clear_and_obvious_inciting].include?(article.automod_label)
        issue_spam_reaction_for!(reactable: article)

        if Reaction.user_has_been_given_too_many_spammy_article_reactions?(
          user: article.user,
          include_user_profile: more_rigorous_user_profile_spam_checking?,
        )
          suspend!(user: article.user)
        end

        return :spam
      end

      # High quality content bypasses spam checks entirely
      if %w[very_good_and_on_topic great_and_on_topic very_good_but_offtopic_for_subforem great_but_off_topic_for_subforem].include?(article.automod_label)
        return :not_spam
      end

      # For likely violations, bypass badge count and other restrictions but still run checks
      bypass_restrictions = %w[likely_spam likely_harmful likely_inciting].include?(article.automod_label)

      # Continue with existing spam detection logic
      text = attributes.map { |attr| article.public_send(attr) }.join("\n")

      # Check if we should trigger spam detection
      should_check = Settings::RateLimit.trigger_spam_for?(text: text) || 
        (article.processed_html.include?("<a") && Ai::Base::DEFAULT_KEY.present? && 
         (bypass_restrictions || article.user.badge_achievements_count < 4) && 
         Ai::ArticleCheck.new(article).spam?)

      return :not_spam unless should_check

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

      # Existing checks for trusted users.
      return :not_spam if comment.user.badge_achievements_count > 6
      return :not_spam if comment.user.base_subscriber?

      if (domain = extract_first_domain_from(comment.processed_html))
        if extensive_domain_spam?(domain: domain, current_comment: comment)
          issue_spam_reaction_for!(reactable: comment)
          suspend_if_user_is_repeat_offender(user: comment.user)
          return :spam # Return early as it's confirmed spam.
        end
      end

      rate_limit_spam = Settings::RateLimit.trigger_spam_for?(text: comment.body_markdown)

      # Return if neither of the spam conditions are met.
      return :not_spam unless rate_limit_spam ||
        (comment.processed_html.include?("<a") && Ai::Base::DEFAULT_KEY.present? && Ai::CommentCheck.new(comment).spam?)

      issue_spam_reaction_for!(reactable: comment)
      suspend_if_user_is_repeat_offender(user: comment.user)
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
    def self.suspend!(user:)
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

    # NEW/private: Helper method to check for extensive domain-based spam.
    def self.extensive_domain_spam?(domain:, current_comment:)
      # Find other comments in the last 48 hours that contain the same domain.
      other_comments = Comment.where("created_at > ?", 48.hours.ago)
        .where.not(id: current_comment.id)
        .where("processed_html LIKE ?", "%#{ActionController::Base.helpers.sanitize(domain)}%")

      # If there are more than 10 other comments, check their scores.
      other_comments_count = other_comments.count
      return false unless other_comments_count > 10

      # Find the number of those comments with a score less than -100.
      low_scoring_comments_count = other_comments.where("score < ?", -100).count

      # If more than 80% are low-scoring, it's considered spam.
      (low_scoring_comments_count.to_f / other_comments_count) > 0.8
    end

    # NEW/private: Helper method to extract the first domain from processed HTML.
    def self.extract_first_domain_from(html)
      href = html&.match(/<a\s+href="([^"]+)"/i)
      return nil unless href

      begin
        URI.parse(href[1]).host
      rescue URI::InvalidURIError
        nil
      end
    end

    # NEW/private: Refactored suspension logic into a helper method for clarity.
    def self.suspend_if_user_is_repeat_offender(user:)
      return unless Reaction.user_has_been_given_too_many_spammy_comment_reactions?(
        user: user,
        include_user_profile: more_rigorous_user_profile_spam_checking?,
      )

      suspend!(user: user)
    end

    # NEW/private: Label article content using AI moderation.
    def self.label_article_content!(article)
      return unless Ai::Base::DEFAULT_KEY.present?

      begin
        labeler = Ai::ContentModerationLabeler.new(article)
        label = labeler.label
        article.update_column(:automod_label, label)
                rescue StandardError => e
            Rails.logger.error("Failed to label article content: #{e}")
            # Set a safe default label
            article.update_column(:automod_label, "no_moderation_label")
          end
    end

    private_class_method :suspend!, :issue_spam_reaction_for!,
                         :extensive_domain_spam?, :extract_first_domain_from,
                         :suspend_if_user_is_repeat_offender, :label_article_content!
  end
end