require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    profile_image: CarrierwaveField,
    username: Field::String,
    twitter_username: Field::String,
    github_username: Field::String,
    summary: Field::String,
    email: Field::String,
    website_url: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    articles: Field::HasMany,
    comments: Field::HasMany,
    reputation_modifier: Field::Number,
    signup_cta_variant: Field::String,
    onboarding_package_requested: Field::Boolean,
    twitter_followers_count: Field::Number,
    bg_color_hex: Field::String,
    text_color_hex: Field::String,
    feed_url: Field::String,
    facebook_url: Field::String,
    behance_url: Field::String,
    dribbble_url: Field::String,
    medium_url: Field::String,
    gitlab_url: Field::String,
    instagram_url: Field::String,
    linkedin_url: Field::String,
    twitch_url: Field::String,
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
    username
    twitter_username
    github_username
    name
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    username
    twitter_username
    github_username
    profile_image
    summary
    website_url
    facebook_url
    behance_url
    dribbble_url
    medium_url
    gitlab_url
    instagram_url
    linkedin_url
    twitch_url
    bg_color_hex
    text_color_hex
    reputation_modifier
    feed_url
    saw_onboarding
  ].freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(user)
    "ID: ##{user.id} - #{user.username}"
  end
end
