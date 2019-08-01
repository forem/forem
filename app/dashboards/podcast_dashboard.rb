require "administrate/base_dashboard"

class PodcastDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    podcast_episodes: Field::HasMany,
    id: Field::Number,
    title: Field::String,
    description: Field::Text,
    feed_url: Field::String,
    itunes_url: Field::String,
    overcast_url: Field::String,
    android_url: Field::String,
    soundcloud_url: Field::String,
    website_url: Field::String,
    main_color_hex: Field::String,
    twitter_username: Field::String,
    image: CarrierwaveField,
    pattern_image: CarrierwaveField,
    slug: Field::String,
    reachable: Field::Boolean,
    published: Field::Boolean,
    status_notice: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    podcast_episodes
    id
    reachable
    published
    status_notice
    title
    description
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    podcast_episodes
    id
    title
    description
    feed_url
    itunes_url
    overcast_url
    android_url
    soundcloud_url
    website_url
    status_notice
    twitter_username
    main_color_hex
    image
    pattern_image
    slug
    reachable
    published
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    podcast_episodes
    title
    description
    status_notice
    feed_url
    itunes_url
    overcast_url
    android_url
    soundcloud_url
    website_url
    twitter_username
    pattern_image
    main_color_hex
    image
    slug
    reachable
    published
  ].freeze

  # Overwrite this method to customize how podcasts are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(podcast)
  #   "Podcast ##{podcast.id}"
  # end
end
