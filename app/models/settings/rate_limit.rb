module Settings
  class RateLimit < RailsSettings::Base
    self.table_name = :settings_rate_limits

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::RateLimit.clear_cache
    cache_prefix { "v1" }

    field :article_update, type: :integer, default: 30
    field :comment_antispam_creation, type: :integer, default: 1
    # Explicitly defaults to 7 to accommodate DEV Top 7 Posts
    field :mention_creation, type: :integer, default: 7
    field :comment_creation, type: :integer, default: 9
    field :email_recipient, type: :integer, default: 5
    field :feedback_message_creation, type: :integer, default: 5
    field :follow_count_daily, type: :integer, default: 500
    field :image_upload, type: :integer, default: 9
    field :listing_creation, type: :integer, default: 1
    field :organization_creation, type: :integer, default: 1
    field :published_article_antispam_creation, type: :integer, default: 1
    field :published_article_creation, type: :integer, default: 9
    field :reaction_creation, type: :integer, default: 10
    field :send_email_confirmation, type: :integer, default: 2
    field :spam_trigger_terms, type: :array, default: []
    field :user_considered_new_days, type: :integer, default: 3
    field :user_subscription_creation, type: :integer, default: 3
    field :user_update, type: :integer, default: 15

    def self.get_default(field)
      get_field(field)[:default]
    end
  end
end
