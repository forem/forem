require "administrate/base_dashboard"

class ArticleDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    user: Field::BelongsTo,
    user_id: UserIdField,
    second_user_id: Field::Number,
    third_user_id: Field::Number,
    organization: Field::BelongsTo,
    id: Field::Number,
    title: Field::String,
    body_html: Field::Text,
    body_markdown: Field::Text,
    slug: Field::String,
    canonical_url: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    main_image: Field::String,
    description: Field::String,
    published: Field::Boolean,
    featured: Field::Boolean,
    approved: Field::Boolean,
    featured_number: Field::Number,
    password: Field::String,
    published_at: Field::DateTime,
    social_image: Field::String,
    collection: Field::BelongsTo,
    show_comments: Field::Boolean,
    main_image_background_hex_color: Field::String,
    comments: Field::HasMany,
    video: Field::String,
    video_code: Field::String,
    video_source_url: Field::String,
    video_thumbnail_url: Field::String,
    video_closed_caption_track_url: Field::String
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    user
    title
    published
    featured
    comments
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    user_id
    second_user_id
    third_user_id
    organization
    title
    body_markdown
    slug
    social_image
    featured
    approved
    featured_number
    canonical_url
    password
    published_at
    collection
    show_comments
    main_image_background_hex_color
    video
    video_code
    video_source_url
    video_thumbnail_url
    video_closed_caption_track_url
  ].freeze

  # Overwrite this method to customize how articles are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(article)
    "Article ##{article.id} - #{article.title}"
  end
end
