class SiteConfigPolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[
    ga_tracking_id
    periodic_email_digest_max
    periodic_email_digest_min
    sidebar_tags
    twitter_hashtag
    shop_url
    payment_pointer
    stripe_api_key
    stripe_publishable_key
    health_check_token
    feed_style
    default_font
    sponsor_headline
    public
    twitter_key
    twitter_secret
    github_key
    github_secret
    facebook_key
    facebook_secret
    allow_email_password_registration
    primary_brand_color_hex

    campaign_featured_tags
    campaign_hero_html_variant_name
    campaign_sidebar_enabled
    campaign_sidebar_image
    campaign_url
    campaign_articles_require_approval

    community_name
    community_description
    community_member_label
    community_action
    community_copyright_start_year
    staff_user_id
    tagline

    mailchimp_api_key
    mailchimp_community_moderators_id
    mailchimp_newsletter_id
    mailchimp_sustaining_members_id
    mailchimp_tag_moderators_id

    rate_limit_comment_creation
    rate_limit_email_recipient
    rate_limit_follow_count_daily
    rate_limit_image_upload
    rate_limit_published_article_creation
    rate_limit_organization_creation
    rate_limit_user_subscription_creation
    rate_limit_article_update
    rate_limit_user_update
    rate_limit_feedback_message_creation
    rate_limit_listing_creation
    rate_limit_reaction_creation
    rate_limit_send_email_confirmation

    mascot_image_description
    mascot_image_url
    mascot_footer_image_url
    mascot_footer_image_width
    mascot_footer_image_height
    mascot_user_id

    favicon_url
    logo_png
    logo_svg
    main_social_image
    secondary_logo_url
    left_navbar_svg_icon
    right_navbar_svg_icon

    onboarding_logo_image
    onboarding_background_image
    onboarding_taskcard_image
    suggested_tags
    suggested_users

    jobs_url
    display_jobs_banner
  ].freeze

  def create?
    current_user?
  end


  def permitted_attributes
    PERMITTED_ATTRIBUTES
  end
end
