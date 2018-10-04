require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    organization: Field::BelongsTo,
    id: Field::Number,
    name: Field::String,
    profile_image: CarrierwaveField,
    username: Field::String,
    twitter_username: Field::String,
    github_username: Field::String,
    banned: UserBannedField,
    reason_for_ban: ReasonForBanField,
    warned: UserWarnedField,
    reason_for_warning: ReasonForWarningField,
    trusted: TrustedUserField,
    scholar: UserScholarField,
    analytics: UserAnalyticsField,
    summary: Field::String,
    email: Field::String,
    website_url: Field::String,
    org_admin: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    articles: Field::HasMany,
    comments: Field::HasMany,
    sign_in_count: Field::Number,
    reputation_modifier: Field::Number,
    signup_cta_variant: Field::String,
    onboarding_package_requested: Field::Boolean,
    onboarding_package_fulfilled: Field::Boolean,
    onboarding_package_requested_again: Field::Boolean,
    twitter_followers_count: Field::Number,
    bg_color_hex: Field::String,
    text_color_hex: Field::String,
    feed_url: Field::String,
    feed_admin_publish_permission: Field::Boolean,
    feed_mark_canonical: Field::Boolean,
    saw_onboarding: Field::Boolean,
    following_tags_count: Field::Number,
    monthly_dues: Field::Number,
    stripe_id_code: Field::String
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    profile_image
    id
    created_at
    username
    name
    twitter_username
    github_username
    following_tags_count
    saw_onboarding
    monthly_dues
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    organization
    name
    username
    twitter_username
    github_username
    profile_image
    org_admin
    banned
    reason_for_ban
    warned
    reason_for_warning
    trusted
    scholar
    analytics
    summary
    website_url
    bg_color_hex
    text_color_hex
    reputation_modifier
    feed_url
    saw_onboarding
  ].freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(user)
  #   user.username
  # end
end
