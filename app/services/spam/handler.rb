module Spam
  # This module is responsible for handling spam in our various user input sources.
  #
  # @note We may not immediately block spam but instead slowly escalate our response.
  module Handler
    # These are purely words that can help trigger an investigation.
    # They are never to be used to directly take any action.
    # They can absolutely be used out of context and only exist to trigger investigation.
    # Depending on the forem, they are hypothetically not even abuse in any way.
    PROFILE_SPAM_TRIGGER_TERMS = [
      "buy links",
      "buying links",
      "backlinks",
      "link building",
      "seo services",
      "casino",
      "gambling",
      "betting",
      "escort",
      "prostitut",
      "adult",
      "girls",
      "porn",
      "onlyfans",
      "crypto pump",
      "forex signals",
      "loan shark",
    ].freeze
    CLEAR_VIOLATION_LABELS = %w[clear_and_obvious_spam clear_and_obvious_harmful clear_and_obvious_inciting].freeze
    HIGH_QUALITY_LABELS = %w[very_good_and_on_topic great_and_on_topic very_good_but_offtopic_for_subforem
                             great_but_off_topic_for_subforem].freeze
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
      if article_linked_domain_spam?(article) || repeated_title_spam?(article)
        article.update_column(:automod_label, "clear_and_obvious_spam")
        article.automod_label = "clear_and_obvious_spam"
      else
        # First, run content moderation labeling
        label_article_content!(article)
      end

      # Handle clear and obvious violations immediately
      if CLEAR_VIOLATION_LABELS.include?(article.automod_label)
        issue_spam_reaction_for!(reactable: article)
        escalate_flagged_author!(user: article.user)

        return :spam
      end

      # High quality content bypasses spam checks entirely
      if HIGH_QUALITY_LABELS.include?(article.automod_label)
        return :not_spam
      end

      # For likely violations, bypass badge count and other restrictions but still run checks
      bypass_restrictions = %w[likely_spam likely_harmful likely_inciting].include?(article.automod_label)

      # Continue with existing spam detection logic
      text = attributes.map { |attr| article.public_send(attr) }.join("\n")

      # Check if we should trigger spam detection
      should_check = Settings::RateLimit.trigger_spam_for?(text: text) ||
        (Ai::FunctionConfig.available?(:article_spam_check) &&
         (bypass_restrictions || article.user.badge_achievements_count < 4) &&
         link_or_escalated?(html: article.processed_html, text: text, content: article) &&
         Ai::ArticleCheck.new(article).spam?)

      return :not_spam unless should_check

      issue_spam_reaction_for!(reactable: article)
      escalate_flagged_author!(user: article.user)
    rescue Ai::Base::ProhibitedContentError
      article.update_column(:automod_label, "clear_and_obvious_harmful")
      spam_block!(reactable: article, user: article.user)
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

      if (domain = extract_first_domain_from(comment.processed_html)) && extensive_domain_spam?(domain: domain,
                                                                                                current_comment: comment)
        issue_spam_reaction_for!(reactable: comment)
        suspend_if_user_is_repeat_offender(user: comment.user)
        return :spam # Return early as it's confirmed spam.
      end

      rate_limit_spam = Settings::RateLimit.trigger_spam_for?(text: comment.body_markdown)

      # Return if neither of the spam conditions are met.
      return :not_spam unless rate_limit_spam ||
        (Ai::FunctionConfig.available?(:comment_spam_check) &&
         link_or_escalated?(html: comment.processed_html, text: comment.body_markdown, content: comment) &&
         Ai::CommentCheck.new(comment).spam?)

      issue_spam_reaction_for!(reactable: comment)
      suspend_if_user_is_repeat_offender(user: comment.user)
    rescue Ai::Base::ProhibitedContentError
      spam_block!(reactable: comment, user: comment.user)
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

    # Test a user profile update for clear and obvious spam or abuse.
    #
    # @param user [User] the user to check for spamminess
    def self.handle_profile_update!(user:)
      return :skipped if user.spam_or_suspended?
      return :skipped unless eligible_for_profile_spam_check?(user: user)
      return :skipped unless Ai::FunctionConfig.available?(:profile_moderation)

      label = Ai::ProfileModerationLabeler.new(user).label
      return :not_spam unless clear_profile_violation_label?(label)

      issue_spam_reaction_for!(reactable: user)

      if label == "clear_and_obvious_spam"
        user.add_role(:spam)
      else
        suspend!(user: user)
      end

      :spam
    rescue Ai::Base::ProhibitedContentError
      spam_block!(reactable: user, user: user)
    end

    # Gemini won't even read prohibited content (e.g. sexual content involving minors), so
    # its refusal is treated as a clear violation: flag the content and mark the author as spam.
    def self.spam_block!(reactable:, user:)
      issue_spam_reaction_for!(reactable: reactable)
      user.add_role(:spam) unless user.spam?
      :spam
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
      reaction = Reaction.create(
        user_id: Settings::General.mascot_user_id,
        reactable: reactable,
        category: "vomit",
      )
      return if reaction.persisted? || reaction.errors.of_kind?(:user_id, :taken)

      Rails.logger.warn("Spam reaction not created for #{reactable.class.name} #{reactable.id}: " \
                        "#{reaction.errors.full_messages.to_sentence}")
    end

    def self.escalate_flagged_author!(user:)
      if Reaction.user_has_been_given_too_many_spammy_article_reactions?(
        user: user,
        include_user_profile: more_rigorous_user_profile_spam_checking?,
      )
        suspend!(user: user)
      elsif repeat_auto_flagged_author?(user: user)
        mark_repeat_auto_flagged_author_as_spam!(user: user)
      end
    end

    # Low-trust authors whose recent posts keep earning the mascot's vomit (from a clear-violation
    # label or the spam check) are treated as spammers without waiting for a moderator to confirm
    # each reaction. The flags must also be most of their recent posts, and any post labeled high
    # quality spares them: content marketers collect a few flags among many good posts.
    def self.repeat_auto_flagged_author?(user:, threshold: 2, min_share: 0.75)
      return false if user.badge_achievements_count >= 4

      recent_articles = user.articles.published.where("published_at > ?", 1.month.ago)
      return false if recent_articles.exists?(automod_label: HIGH_QUALITY_LABELS)

      flagged_count = recent_auto_flagged_article_count(user: user)
      flagged_count > threshold && flagged_count >= min_share * recent_articles.count
    end

    # On-topic posts the spam check flagged as promotion don't count: that's content marketing.
    def self.recent_auto_flagged_article_count(user:)
      recent_articles = user.articles.published.where("published_at > ?", 1.month.ago)
        .where.not(automod_label: "okay_and_on_topic")
      Reaction.article_vomits.valid_or_confirmed
        .where(user_id: Settings::General.mascot_user_id, reactable_id: recent_articles.select(:id))
        .count
    end

    # Leave a note so moderators can see why the account was marked as spam. Skipped when the
    # author is already spam so queued jobs for the same author don't pile up duplicate notes.
    def self.mark_repeat_auto_flagged_author_as_spam!(user:)
      return if user.spam?

      user.add_role(:spam)

      Note.create(
        author_id: Settings::General.mascot_user_id,
        noteable: user,
        reason: "automatic_spam",
        content: I18n.t("services.spam.article_handler.marked_spam_repeat_auto_flags",
                        count: recent_auto_flagged_article_count(user: user)),
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
      return unless href

      begin
        URI.parse(href[1]).host
      rescue URI::InvalidURIError
        nil
      end
    end

    # Content with a link always goes to the spam check. Without a link, it goes only when the
    # cheaper Jev escalation check flags it (e.g. Telegram/WhatsApp contacts written as text).
    # That check is off unless :spam_escalation is set to Jev in Ai::FunctionConfig.
    def self.link_or_escalated?(html:, text:, content:)
      html.include?("<a") || Ai::SpamEscalationCheck.new(text: text, content: content).escalate?
    end
    private_class_method :link_or_escalated?

    # NEW/private: Refactored suspension logic into a helper method for clarity.
    def self.suspend_if_user_is_repeat_offender(user:)
      return unless Reaction.user_has_been_given_too_many_spammy_comment_reactions?(
        user: user,
        include_user_profile: more_rigorous_user_profile_spam_checking?,
      )

      suspend!(user: user)
    end

    # NEW/private: Label article content using AI moderation and calculate compellingness.
    def self.label_article_content!(article)
      return unless Ai::FunctionConfig.available?(:content_moderation)

      begin
        labeler = Ai::ContentModerationLabeler.new(article)
        results = labeler.evaluate
        label = results[:label]
        
        article.update_columns(
          automod_label: label,
          compellingness_score: results[:compellingness_score]
        )

        # Only check for subforem reassignment if the article is marked as offtopic
        if offtopic_label?(label)
          check_subforem_reassignment(article)
        end
      rescue Ai::Base::ProhibitedContentError
        raise
      rescue StandardError => e
        Rails.logger.error("Failed to label article content: #{e}")
        # Set a safe default label
        article.update_columns(automod_label: "no_moderation_label", compellingness_score: 0.0)
      end
    end

    # NEW/private: Check if a label indicates the content is offtopic
    def self.offtopic_label?(label)
      %w[
        ok_but_offtopic_for_subforem
        very_good_but_offtopic_for_subforem
        great_but_off_topic_for_subforem
      ].include?(label)
    end

    # NEW/private: Check if article should be reassigned to a different subforem
    def self.check_subforem_reassignment(article)
      return unless Ai::FunctionConfig.available?(:subforem_matching)
      return if ENV["SKIP_SUBFOREM_REASSIGNMENT"] == "yes"

      begin
        reassignment_service = SubforemReassignmentService.new(article)
        reassignment_service.check_and_reassign
      rescue StandardError => e
        Rails.logger.error("Failed to check subforem reassignment for article #{article.id}: #{e}")
      end
    end

    # NEW/private: Determine if a profile label is a clear violation.
    def self.clear_profile_violation_label?(label)
      CLEAR_VIOLATION_LABELS.include?(label)
    end

    # NEW/private: Skip profile checks for established accounts.
    def self.eligible_for_profile_spam_check?(user:)
      return false if published_articles_over_limit?(user: user)
      return false if published_comments_over_limit?(user: user)

      true
    end

    def self.published_articles_over_limit?(user:, limit: 3)
      user.articles.published.limit(limit + 1).count > limit
    end

    def self.published_comments_over_limit?(user:, limit: 3)
      user.comments.where(deleted: false).limit(limit + 1).count > limit
    end

    # NEW/private: Detects trigger terms in profile text.
    def self.profile_spam_trigger_term_match?(text)
      normalized = text.to_s.downcase
      return false if normalized.blank?

      PROFILE_SPAM_TRIGGER_TERMS.any? { |term| normalized.include?(term) }
    end

    # Spam farms publish the same post over and over. The third copy of a title in a day is spam
    # whatever it says, and whatever the author's badges.
    def self.repeated_title_spam?(article, limit: 3)
      article.user.articles.published
        .where(title: article.title)
        .where("published_at > ?", 1.day.ago)
        .count >= limit
    end

    # NEW/private: Check if article links to highly negative domains
    def self.article_linked_domain_spam?(article)
      html = article.processed_html
      return false if html.blank? || !html.include?("<a")

      score = article.user.score
      return false if score > 50

      threshold = linked_domain_spam_net_score_threshold(score)

      domains = extract_all_domains_from(html, limit: 25)
      return false if domains.empty?

      LinkedDomain.where(host: domains).where("net_score <= ?", threshold).exists?
    end

    # The (negative) net_score at or below which a linked domain flags a post
    # by an author with the given score. Higher-score authors get more slack:
    # the base threshold is multiplied by 1 + (score / 10).
    def self.linked_domain_spam_net_score_threshold(author_score)
      base = Settings::RateLimit.linked_domain_spam_score_threshold.to_i
      multiplier = author_score <= 0 ? 1 : 1 + (author_score / 10)
      -(base * multiplier)
    end

    # NEW/private: Extract all domains from processed HTML
    def self.extract_all_domains_from(html, limit: 25)
      return [] if html.blank? || !html.include?("<a") || limit.to_i <= 0

      domains = []
      seen_domains = {}

      html.to_enum(:scan, /<a\s+[^>]*href=(['"])(.*?)\1/i).each do
        begin
          host = URI.parse(Regexp.last_match(2)).host&.downcase
        rescue URI::Error
          next
        end

        next if host.blank? || seen_domains[host]

        seen_domains[host] = true
        domains << host
        break if domains.size >= limit
      end

      domains
    end

    private_class_method :suspend!, :issue_spam_reaction_for!,
                         :extensive_domain_spam?, :extract_first_domain_from,
                         :suspend_if_user_is_repeat_offender, :label_article_content!,
                         :offtopic_label?, :check_subforem_reassignment,
                         :clear_profile_violation_label?, :eligible_for_profile_spam_check?,
                         :published_articles_over_limit?, :published_comments_over_limit?,
                         :article_linked_domain_spam?, :extract_all_domains_from, :repeated_title_spam?,
                         :escalate_flagged_author!, :repeat_auto_flagged_author?,
                         :spam_block!,
                         :recent_auto_flagged_article_count, :mark_repeat_auto_flagged_author_as_spam!
  end
end
