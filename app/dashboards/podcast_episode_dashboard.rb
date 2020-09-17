require "administrate/base_dashboard"

class PodcastEpisodeDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    subtitle: Field::String,
    summary: Field::Text,
    body: Field::Text,
    quote: Field::Text,
    processed_html: Field::Text,
    comments_count: Field::Number,
    reactions_count: Field::Number,
    media_url: Field::String,
    website_url: Field::String,
    itunes_url: Field::String,
    image: CarrierwaveField,
    podcast: Field::BelongsTo,
    published_at: Field::DateTime,
    slug: Field::String,
    guid: Field::String,
    reachable: Field::Boolean,
    https: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    social_image: CarrierwaveField
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    title
    media_url
    reachable
    https
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    podcast
    title
    image
    social_image
    body
    media_url
    website_url
    itunes_url
    published_at
    slug
    reachable
    https
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    title
    body
    website_url
    media_url
    itunes_url
    social_image
    published_at
  ].freeze

  # Overwrite this method to customize how podcast episodes are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(podcast_episode)
  #   "PodcastEpisode ##{podcast_episode.id}"
  # end
end
