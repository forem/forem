require "administrate/base_dashboard"

class DisplayAdDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    organization: Field::BelongsTo,
    id: Field::Number,
    placement_area: Field::String,
    body_markdown: Field::Text,
    processed_html: Field::Text,
    impressions_count: Field::Number,
    clicks_count: Field::Number,
    success_rate: Field::Number,
    published: Field::Boolean,
    approved: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    organization
    id
    placement_area
    body_markdown
    published
    approved
    success_rate
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    organization
    id
    placement_area
    body_markdown
    processed_html
    impressions_count
    clicks_count
    success_rate
    published
    approved
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    organization
    placement_area
    body_markdown
    published
    approved
  ].freeze

  # Overwrite this method to customize how display ads are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(display_ad)
  #   "DisplayAd ##{display_ad.id}"
  # end
end
