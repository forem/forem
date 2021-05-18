module DataUpdateScripts
  class CleanUpSiteConfig
    OBSOLETE_FIELDS = %w[
      allowed_registration_email_domains
      authentication_providers
      campaign_articles_expiry_time
      campaign_articles_require_approval
      campaign_call_to_action
      campaign_featured_tags
      campaign_hero_html_variant_name
      campaign_sidebar_enabled
      campaign_sidebar_image
      campaign_url
      collective_noun
      collective_noun_disabled
      community_copyright_start_year
      community_description
      community_emoji
      community_member_label
      community_name
      default_font
      experience_high
      experience_low
      feed_strategy
      feed_style
      home_feed_minimum_score
      primary_brand_color_hex
      public
      rate_limit_article_update
      rate_limit_comment_antispam_creation
      rate_limit_comment_creation
      rate_limit_email_recipient
      rate_limit_feedback_message_creation
      rate_limit_follow_count_daily
      rate_limit_image_upload
      rate_limit_listing_creation
      rate_limit_organization_creation
      rate_limit_published_article_antispam_creation
      rate_limit_published_article_creation
      rate_limit_reaction_creation
      rate_limit_send_email_confirmation
      rate_limit_user_subscription_creation
      rate_limit_user_update
      spam_trigger_terms
      staff_user_id
      tag_feed_minimum_score
      tagline
      user_considered_new_days
    ].freeze

    def run
      SiteConfig.delete_by(var: OBSOLETE_FIELDS)
    end
  end
end
