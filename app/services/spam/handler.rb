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
      "porn",
      "onlyfans",
      "crypto pump",
      "forex signals",
      "loan shark",
    ].freeze
    CLEAR_VIOLATION_LABELS = %w[clear_and_obvious_spam clear_and_obvious_harmful clear_and_obvious_inciting].freeze
    HIGH_QUALITY_LABELS = %w[very_good_and_on_topic great_and_on_topic very_good_but_offtopic_for_subforem
                             great_but_off_topic_for_subforem].freeze
    MINIMUM_INDEXED_ARTICLE_LABEL = "okay_and_on_topic".freeze
    PLATFORM_IMPERSONATION_PATTERN = /\b(?:
      (?:dev(?:\.to)?|forem)\s+(?:
        support|team|staff|admin(?:istrator)?s?|security|mod(?:erator)?s?|official|help\s*desk|verif\w*|bot
      ) |
      official\s+(?:account|support|team|staff|bot|notice|verification)\b.*?\b(?:dev|forem|platform|community) |
      (?:support|security|verification)\s+(?:team|bot|staff|desk)\b
    )/ix
    PHISHING_OR_SIGNUP_PATTERN = /\b(?:
      mandatory\s+(?:user\s+|account\s+)?verif\w* |
      require\s+verif\w*\s+of\s+your\s+account |
      verif\w*\s+(?:your\s+account|deadline|required|immediately) |
      failure\s+to\s+verif\w* |
      restricted\s+access |
      log\s*in\s+via\s+(?:the\s+)?link |
      confirm\s+your\s+(?:account|identity|credentials) |
      sign\s*up\s+(?:
        now|here|today|via|at|below|link|for\s+free|to\s+(?:claim|get|receive|unlock|verify|continue|access)
      ) |
      register\s+(?:now|here|today|via|at|below|your\s+account|to\s+(?:claim|get|receive|unlock|verify)) |
      create\s+(?:an?\s+)?(?:free\s+)?account\s+(?:now|here|today|via|at|below)
    )/ix
    SHORTENER_LINK_PATTERN = %r{
      \b(?:https?://)?
      (?:tr\.ee|bit\.ly|tinyurl\.com|t\.co|rb\.gy|is\.gd|cutt\.ly|rebrand\.ly|shorturl\.at)/[A-Za-z0-9_-]+
    }ix
    LINKED_SIGNUP_CUE_PATTERN = /\b(?:
      sign\s*up|signup|register|log\s*in|verif\w*|official|support|claim\s+your|free\s+account
    )\b/ix
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
      assign_article_automod_label!(article)
      return :not_spam if minimum_indexed_article?(article)

      text = attributes.map { |attr| article.public_send(attr) }.join("\n")

      # Handle clear and obvious violations immediately
      if CLEAR_VIOLATION_LABELS.include?(article.automod_label)
        issue_spam_reaction_for!(reactable: article)
        escalate_or_mark_phishing_article_author!(article: article, text: text)
        return :spam
      end

      # High quality content bypasses spam checks entirely
      if HIGH_QUALITY_LABELS.include?(article.automod_label)
        return :not_spam
      end

      return :spam if handle_phishing_or_signup_article!(article: article, text: text)

      # For likely violations, bypass badge count and other restrictions but still run checks
      bypass_restrictions = %w[likely_spam likely_harmful likely_inciting].include?(article.automod_label)

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
      handle_prohibited_article_content!(article)
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

      if (count = new_account_comment_flood_count(user: comment.user))
        mark_as_spam!(user: comment.user, reason: "new_account_comment_flood", commented_post_count: count,
                      note: I18n.t("services.spam.comment_handler.marked_spam_comment_flood", count: count))
        return :spam
      end

      if (domain = extract_first_domain_from(comment.processed_html)) && extensive_domain_spam?(domain: domain,
                                                                                                current_comment: comment)
        issue_spam_reaction_for!(reactable: comment)
        escalate_flagged_commenter!(user: comment.user)
        return :spam # Return early as it's confirmed spam.
      end

      if low_trust_phishing_or_signup_spam?(record: comment, text: comment.body_markdown,
                                            html: comment.processed_html, parent_content: comment.commentable)
        issue_spam_reaction_for!(reactable: comment)
        mark_low_trust_phishing_or_signup_spam!(user: comment.user, reactable: comment)
        return :spam
      end

      rate_limit_spam = Settings::RateLimit.trigger_spam_for?(text: comment.body_markdown)

      # Return if neither of the spam conditions are met.
      return :not_spam unless rate_limit_spam ||
        (Ai::FunctionConfig.available?(:comment_spam_check) &&
         link_or_escalated?(html: comment.processed_html, text: comment.body_markdown, content: comment) &&
         Ai::CommentCheck.new(comment).spam?)

      issue_spam_reaction_for!(reactable: comment)
      escalate_flagged_commenter!(user: comment.user)
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
      return :spam if handle_phishing_or_signup_profile!(user: user)
      return :skipped unless Ai::FunctionConfig.available?(:profile_moderation)

      label = Ai::ProfileModerationLabeler.new(user).label
      return :not_spam unless clear_profile_violation_label?(label)

      issue_spam_reaction_for!(reactable: user)
      return :spam if exempt_from_auto_block?(user: user)

      # Snapshot the profile: users often clear it after being blocked, leaving moderators nothing to review.
      details = { reason: "profile_moderation", label: label, name: user.name, summary: user.profile&.summary,
                  website_url: user.profile&.website_url, location: user.profile&.location }
      if label == "clear_and_obvious_spam"
        user.add_role(:spam)
        audit_automatic_block!(user: user, role: :spam, **details)
      else
        suspend!(user: user, **details)
      end

      :spam
    rescue Ai::Base::ProhibitedContentError
      spam_block!(reactable: user, user: user)
    end

    # Every automated spam or suspended role is audited so moderators can see why an account was
    # blocked. Shows up under the user's admin "on user" audit log tab.
    #
    # @param role [Symbol] :spam or :suspended
    # @param reason [String] which automated check blocked the user
    def self.audit_automatic_block!(user:, role:, reason:, **details)
      AuditLog.create(
        user_id: Settings::General.mascot_user_id,
        category: "spam.automatic_block",
        slug: "automatic_#{role}",
        data: { action: "automatic_#{role}", target_user_id: user.id, reason: reason, **details },
      )
    end

    # Gemini won't even read prohibited content (e.g. sexual content involving minors), so
    # its refusal is treated as a clear violation: flag the content and mark the author as spam.
    def self.spam_block!(reactable:, user:)
      issue_spam_reaction_for!(reactable: reactable)
      unless user.spam? || exempt_from_auto_block?(user: user)
        user.add_role(:spam)
        audit_automatic_block!(user: user, role: :spam, reason: "prohibited_content",
                               reactable_type: reactable.class.name, reactable_id: reactable.id)
      end
      :spam
    end

    # Suspend the given user because of too many spammy actions.
    #
    # @param user [User]
    # @param reason [String] which automated check suspended the user, for the audit log
    def self.suspend!(user:, reason: "too_many_spam_reactions", **details)
      return if exempt_from_auto_block?(user: user)

      user.add_role(:suspended)
      unpublish = unpublish_all_posts_when_user_auto_suspended?
      # Recorded so an approved appeal (Appeals::Resolver) can restore exactly the posts hidden here.
      # Not the `published` scope: scheduled posts must be hidden too.
      details[:unpublished_article_ids] = user.articles.where(published: true).ids if unpublish
      audit_automatic_block!(user: user, role: :suspended, reason: reason, **details)

      Note.create(
        author_id: Settings::General.mascot_user_id,
        noteable: user,
        reason: "automatic_suspend",
        content: I18n.t("models.comment.suspended_too_many"),
      )

      return unless unpublish

      user.articles.where(id: details[:unpublished_article_ids]).update_all(published: false)
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
      if reaction.persisted? ||
          (reaction.errors.of_kind?(:user_id, :taken) && active_spam_reaction_for?(reactable: reactable))
        remove_spam_comment_notifications!(comment: reactable) if reactable.is_a?(Comment)
        return
      end
      return if reaction.errors.of_kind?(:user_id, :taken)

      Rails.logger.warn("Spam reaction not created for #{reactable.class.name} #{reactable.id}: " \
                        "#{reaction.errors.full_messages.to_sentence}")
    end

    # Checks whether the mascot has already left an active vomit reaction on the given reactable.
    #
    # @param reactable [ActiveRecord::Base]
    # @return [Boolean]
    def self.active_spam_reaction_for?(reactable:)
      Reaction.valid_or_confirmed.exists?(
        user_id: Settings::General.mascot_user_id,
        reactable: reactable,
        category: "vomit",
      )
    end

    # New comment and mention notifications go out when the comment is saved, before the async
    # spam check runs. Once the mascot flags the comment, pull them back so recipients don't keep
    # seeing (and clicking through to) spam in their notifications inbox.
    def self.remove_spam_comment_notifications!(comment:)
      Notification.remove_all_without_delay(notifiable_ids: comment.id, notifiable_type: "Comment")
      Notification.remove_all_without_delay(notifiable_ids: comment.mentions.ids, notifiable_type: "Mention")
    end

    def self.escalate_flagged_author!(user:)
      if Reaction.user_has_been_given_too_many_spammy_article_reactions?(
        user: user,
        include_user_profile: more_rigorous_user_profile_spam_checking?,
      )
        suspend!(user: user)
      elsif repeat_auto_flagged_author?(user: user)
        count = recent_auto_flagged_article_count(user: user)
        mark_as_spam!(user: user, reason: "repeat_auto_flagged_articles", flagged_article_count: count,
                      note: I18n.t("services.spam.article_handler.marked_spam_repeat_auto_flags", count: count))
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

    # Same rule for comments. The flags must cover a share of the user's recent comments, so an
    # active commenter whose links were misflagged a few times isn't caught. A phishing bot posting
    # hundreds of comments gets most of them past the escalation check, so its flags never reach
    # that share; a high flag count alone is enough for it.
    def self.repeat_auto_flagged_commenter?(user:, threshold: 2, min_share: 0.5, volume_threshold: 10)
      return false if user.badge_achievements_count >= 4

      flagged_count = recent_auto_flagged_comment_count(user: user)
      return false unless flagged_count > threshold
      return true if flagged_count >= volume_threshold

      flagged_count >= min_share * recent_comments(user: user).count
    end

    def self.recent_auto_flagged_comment_count(user:)
      Reaction.comment_vomits.valid_or_confirmed
        .where(user_id: Settings::General.mascot_user_id, reactable_id: recent_comments(user: user).select(:id))
        .count
    end

    def self.recent_comments(user:)
      user.comments.where("created_at > ?", 1.month.ago)
    end

    # Moderator-confirmed flags suspend the commenter; the mascot's own flags mark them as spam.
    def self.escalate_flagged_commenter!(user:)
      if Reaction.user_has_been_given_too_many_spammy_comment_reactions?(
        user: user,
        include_user_profile: more_rigorous_user_profile_spam_checking?,
      )
        suspend!(user: user)
      elsif repeat_auto_flagged_commenter?(user: user)
        count = recent_auto_flagged_comment_count(user: user)
        mark_as_spam!(user: user, reason: "repeat_auto_flagged_comments", flagged_comment_count: count,
                      note: I18n.t("services.spam.comment_handler.marked_spam_repeat_auto_flags", count: count))
      end
    end

    # Comment farms sign up fresh accounts that comment on dozens of posts a day with on-topic,
    # AI-written text that no content check flags. Newcomers rarely comment on more than 15
    # posts in a day.
    #
    # @return [Integer, nil] how many posts a new account commented on in the last day, when over the limit
    def self.new_account_comment_flood_count(user:, limit: 20)
      return unless user.registered_at&.after?(3.days.ago)
      # Staff, trusted accounts, and members of minimum-indexed organizations may seed discussions.
      return if user.auditable? || user.super_moderator? || exempt_from_auto_block?(user: user)

      count = user.comments.where("created_at > ?", 24.hours.ago).distinct.count(:commentable_id)
      count if count > limit
    end

    # Leave a note so moderators can see why the account was marked as spam. Skipped when the
    # user is already spam so queued jobs for the same user don't pile up duplicate notes.
    def self.mark_as_spam!(user:, reason:, note:, **details)
      return if user.spam? || exempt_from_auto_block?(user: user)

      user.add_role(:spam)
      Notifications::RemoveBySpammerWorker.perform_async(user.id)
      audit_automatic_block!(user: user, role: :spam, reason: reason, **details)

      Note.create(
        author_id: Settings::General.mascot_user_id,
        noteable: user,
        reason: "automatic_spam",
        content: note,
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

    def self.assign_article_automod_label!(article)
      if !minimum_indexed_article?(article) && (article_linked_domain_spam?(article) || repeated_title_spam?(article))
        article.update_column(:automod_label, "clear_and_obvious_spam")
        article.automod_label = "clear_and_obvious_spam"
      else
        label_article_content!(article)
      end
    end

    # NEW/private: Label article content using AI moderation and calculate compellingness.
    def self.label_article_content!(article)
      unless Ai::FunctionConfig.available?(:content_moderation)
        ensure_minimum_indexed_label!(article) if minimum_indexed_article?(article)
        return
      end

      begin
        labeler = Ai::ContentModerationLabeler.new(article)
        results = labeler.evaluate
        label = apply_minimum_indexed_label_floor(article, results[:label])

        article.update_columns(
          automod_label: label,
          compellingness_score: results[:compellingness_score],
        )
        article.automod_label = label

        # Only check for subforem reassignment if the article is marked as offtopic
        if offtopic_label?(label)
          check_subforem_reassignment(article)
        end
      rescue Ai::Base::ProhibitedContentError
        raise
      rescue StandardError => e
        Rails.logger.error("Failed to label article content: #{e}")
        # Set a safe default label
        fallback_label = apply_minimum_indexed_label_floor(article, "no_moderation_label")
        article.update_columns(automod_label: fallback_label, compellingness_score: 0.0)
        article.automod_label = fallback_label
      end
    end

    def self.handle_prohibited_article_content!(article)
      if minimum_indexed_article?(article)
        ensure_minimum_indexed_label!(article)
        return :not_spam
      end

      article.update_column(:automod_label, "clear_and_obvious_harmful")
      spam_block!(reactable: article, user: article.user)
    end

    def self.minimum_indexed_article?(article)
      article.organization&.baseline_score.to_i.positive? ||
        article.baseline_score.to_i.positive? ||
        article.user&.base_subscriber? == true ||
        article.user&.member_of_minimum_indexed_organization? == true
    end

    def self.apply_minimum_indexed_label_floor(article, label)
      return label unless minimum_indexed_article?(article)
      return label if HIGH_QUALITY_LABELS.include?(label.to_s)

      MINIMUM_INDEXED_ARTICLE_LABEL
    end

    def self.ensure_minimum_indexed_label!(article)
      floored_label = apply_minimum_indexed_label_floor(article, article.automod_label)
      return if article.automod_label == floored_label

      article.update_column(:automod_label, floored_label)
      article.automod_label = floored_label
    end

    def self.exempt_from_auto_block?(user:)
      user&.member_of_minimum_indexed_organization? == true
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
      raw = text.to_s
      return false if raw.blank?
      return true if Ai::PhishingSignupCheck.unicode_obfuscated?(raw)

      normalized = Ai::PhishingSignupCheck.normalize_obfuscated_text(raw).downcase
      return true if normalized.match?(PLATFORM_IMPERSONATION_PATTERN)

      PROFILE_SPAM_TRIGGER_TERMS.any? do |term|
        pattern = term == "prostitut" ? /\b#{Regexp.escape(term)}\w*\b/ : /\b#{Regexp.escape(term)}s?\b/
        normalized.match?(pattern)
      end
    end

    # Determines whether a user is a low-trust account eligible for phishing/signup checks.
    #
    # @param user [User, nil]
    # @return [Boolean]
    def self.low_trust_user?(user)
      return false unless user
      return false if exempt_from_auto_block?(user: user)
      return false if user.trusted? || user.auditable? || user.super_moderator? || user.base_subscriber?

      user.badge_achievements_count.to_i < 4
    end

    # Determines whether a low-trust user's content or profile has candidate cues for phishing or signup spam.
    #
    # @param user [User, nil]
    # @param text [String, nil]
    # @param html [String, nil]
    # @param parent_content [ActiveRecord::Base, nil]
    # @return [Boolean]
    def self.phishing_or_signup_candidate?(user:, text: nil, html: nil, parent_content: nil)
      return false unless low_trust_user?(user)

      author_text = [user.name, user.username, user.profile&.summary, user.profile&.website_url].compact.join("\n")
      return true if text_has_phishing_or_signup_cues?(author_text)
      return true if text_has_phishing_or_signup_cues?(text, html: html)
      return true if parent_content && parent_has_phishing_or_signup_cues?(parent_content)

      false
    end

    # Checks whether text or HTML contains Unicode obfuscation, platform impersonation,
    # phishing/verification prompts, URL shorteners, or linked signup cues.
    #
    # @param text [String, nil]
    # @param html [String, nil]
    # @return [Boolean]
    def self.text_has_phishing_or_signup_cues?(text, html: nil)
      raw = text.to_s
      return false if raw.blank?
      return true if Ai::PhishingSignupCheck.unicode_obfuscated?(raw)

      normalized = Ai::PhishingSignupCheck.normalize_obfuscated_text(raw)
      return true if normalized.match?(PLATFORM_IMPERSONATION_PATTERN)
      return true if normalized.match?(PHISHING_OR_SIGNUP_PATTERN)
      return true if normalized.match?(SHORTENER_LINK_PATTERN)

      (html.to_s.include?("<a") || normalized.match?(%r{https?://}i)) &&
        normalized.match?(LINKED_SIGNUP_CUE_PATTERN)
    end

    # Checks whether a parent post (such as the article a comment replies to) has phishing/signup cues.
    #
    # @param parent_content [ActiveRecord::Base, nil]
    # @return [Boolean]
    def self.parent_has_phishing_or_signup_cues?(parent_content)
      parent_text = [
        parent_content.respond_to?(:title) ? parent_content.title : nil,
        parent_content.respond_to?(:body_markdown) ? parent_content.body_markdown : nil,
      ].compact.join("\n")
      text_has_phishing_or_signup_cues?(parent_text)
    end

    # Immediately marks a low-trust author as spam if the flagged article is phishing/signup spam;
    # otherwise uses standard author escalation.
    def self.escalate_or_mark_phishing_article_author!(article:, text:)
      if low_trust_phishing_or_signup_spam?(record: article, text: text, html: article.processed_html)
        mark_low_trust_phishing_or_signup_spam!(user: article.user, reactable: article)
      else
        escalate_flagged_author!(user: article.user)
      end
    end

    # Runs the low-trust phishing/signup AI check on an article and flags/blocks the author if matched.
    #
    # @return [Boolean] true if handled as phishing/signup spam
    def self.handle_phishing_or_signup_article!(article:, text:)
      return false unless low_trust_phishing_or_signup_spam?(record: article, text: text, html: article.processed_html)

      article.update_column(:automod_label, "clear_and_obvious_spam")
      article.automod_label = "clear_and_obvious_spam"
      issue_spam_reaction_for!(reactable: article)
      mark_low_trust_phishing_or_signup_spam!(user: article.user, reactable: article)
      true
    end

    # Runs the low-trust phishing/signup AI check on a user profile update and flags/blocks the user if matched.
    #
    # @return [Boolean] true if handled as phishing/signup spam
    def self.handle_phishing_or_signup_profile!(user:)
      profile_text = [user.name, user.username, user.profile&.summary, user.profile&.website_url].compact.join("\n")
      return false unless low_trust_phishing_or_signup_spam?(record: user, text: profile_text)

      issue_spam_reaction_for!(reactable: user)
      mark_low_trust_phishing_or_signup_spam!(
        user: user,
        reactable: user,
        name: user.name,
        summary: user.profile&.summary,
        website_url: user.profile&.website_url,
        location: user.profile&.location,
      )
      true
    end

    # Evaluates whether a record from a low-trust user is confirmed phishing/signup spam via AI.
    #
    # @return [Boolean]
    def self.low_trust_phishing_or_signup_spam?(record:, text: nil, html: nil, parent_content: nil)
      user = record.is_a?(User) ? record : record.user
      return false unless low_trust_user?(user)
      return false unless Ai::FunctionConfig.available?(:phishing_signup_check)
      return false unless phishing_or_signup_candidate?(user: user, text: text, html: html,
                                                        parent_content: parent_content)

      Ai::PhishingSignupCheck.new(record).spam?
    end

    # Marks a low-trust user as spam (or suspends them if over the spam reaction threshold)
    # with an audit log entry and moderator note.
    def self.mark_low_trust_phishing_or_signup_spam!(user:, reactable:, **details)
      too_many_reactions = if reactable.is_a?(Comment)
                             Reaction.user_has_been_given_too_many_spammy_comment_reactions?(
                               user: user,
                               include_user_profile: more_rigorous_user_profile_spam_checking?,
                             )
                           else
                             Reaction.user_has_been_given_too_many_spammy_article_reactions?(
                               user: user,
                               include_user_profile: more_rigorous_user_profile_spam_checking?,
                             )
                           end
      if too_many_reactions
        suspend!(user: user)
        return
      end

      mark_as_spam!(
        user: user,
        reason: "low_trust_phishing_or_signup",
        note: I18n.t("services.spam.phishing_or_signup.marked_spam"),
        reactable_type: reactable.class.name,
        reactable_id: reactable.id,
        **details,
      )
    end

    # Spam farms publish the same post over and over. The third copy of a title in a day is spam
    # whatever it says, and whatever the author's badges. Only this copy and the ones before it
    # count, so a late or repeated check never flags an earlier copy.
    def self.repeated_title_spam?(article, limit: 3)
      return false unless article.published_at

      article.user.articles.published
        .where(title: article.title)
        .where(published_at: (article.published_at - 1.day)..article.published_at)
        .where("articles.published_at < ? OR articles.id <= ?", article.published_at, article.id)
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

    private_class_method :suspend!, :issue_spam_reaction_for!, :remove_spam_comment_notifications!,
                         :extensive_domain_spam?, :extract_first_domain_from,
                         :escalate_flagged_commenter!, :assign_article_automod_label!, :label_article_content!,
                         :handle_prohibited_article_content!, :minimum_indexed_article?,
                         :apply_minimum_indexed_label_floor,
                         :ensure_minimum_indexed_label!, :exempt_from_auto_block?,
                         :offtopic_label?, :check_subforem_reassignment,
                         :clear_profile_violation_label?, :eligible_for_profile_spam_check?,
                         :published_articles_over_limit?, :published_comments_over_limit?,
                         :article_linked_domain_spam?, :extract_all_domains_from, :repeated_title_spam?,
                         :escalate_flagged_author!, :repeat_auto_flagged_author?,
                         :spam_block!,
                         :recent_auto_flagged_article_count, :mark_as_spam!,
                         :repeat_auto_flagged_commenter?, :recent_auto_flagged_comment_count, :recent_comments,
                         :new_account_comment_flood_count,
                         :low_trust_phishing_or_signup_spam?, :mark_low_trust_phishing_or_signup_spam!,
                         :text_has_phishing_or_signup_cues?, :parent_has_phishing_or_signup_cues?,
                         :escalate_or_mark_phishing_article_author!, :handle_phishing_or_signup_article!,
                         :handle_phishing_or_signup_profile!
  end
end
