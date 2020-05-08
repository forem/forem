require "administrate/base_dashboard"

class ClassifiedListingCategoryDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    classified_listings: Field::HasMany,
    id: Field::Number,
    cost: Field::Number,
    created_at: Field::DateTime,
    name: Field::String,
    rules: Field::String,
    slug: Field::String,
    social_preview_description: Field::String,
    social_preview_color: Field::String,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    name
    slug
    rules
    cost
    social_preview_description
    social_preview_color
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    rules
    cost
    social_preview_description
    social_preview_color
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    slug
    rules
    cost
    social_preview_description
    social_preview_color
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how classified listing categories are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(classified_listing_category)
  #   "ClassifiedListingCategory ##{classified_listing_category.id}"
  # end
end
