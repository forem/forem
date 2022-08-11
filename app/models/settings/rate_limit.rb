module Settings
  class RateLimit < Base
    self.table_name = :settings_rate_limits

    setting :article_update, type: :integer, default: 30
    setting :comment_antispam_creation, type: :integer, default: 1
    # Explicitly defaults to 7 to accommodate DEV Top 7 Posts
    setting :mention_creation, type: :integer, default: 7
    setting :comment_creation, type: :integer, default: 9
    setting :email_recipient, type: :integer, default: 5
    setting :feedback_message_creation, type: :integer, default: 5
    setting :follow_count_daily, type: :integer, default: 500
    setting :image_upload, type: :integer, default: 9
    setting :listing_creation, type: :integer, default: 1
    setting :organization_creation, type: :integer, default: 1
    setting :published_article_antispam_creation, type: :integer, default: 1
    setting :published_article_creation, type: :integer, default: 9
    setting :reaction_creation, type: :integer, default: 10
    setting :send_email_confirmation, type: :integer, default: 2
    setting :spam_trigger_terms, type: :array, default: []
    setting :user_considered_new_days, type: :integer, default: 3
    setting :user_subscription_creation, type: :integer, default: 3
    setting :user_update, type: :integer, default: 15

    # A helper function to determine if we should consider the user a "new" user.
    #
    # @note A "new" user is more likely to start spamming than an "old" user.
    #
    # @param user [User, UserDecorator]
    #
    # @return [Boolean]
    def self.user_considered_new?(user:)
      return true unless user
      return false unless user_considered_new_days.positive?

      user.created_at.after?(user_considered_new_days.days.ago)
    end

    # A helper function to determine if text is spammy.
    #
    # @param text [String] text to check for "spamminess"
    #
    # @return [TrueClass] if this is spammy
    # @return [FalseClass] if this isn't spammy
    def self.trigger_spam_for?(text:)
      return false if spam_trigger_terms.empty?

      regexp = Regexp.new("(#{spam_trigger_terms.map { |term| Regexp.escape(term) }.join('|')})", true)
      regexp.match?(text)
    end
  end
end
