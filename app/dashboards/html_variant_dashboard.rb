require "administrate/base_dashboard"

class HtmlVariantDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    user: Field::BelongsTo,
    html_variant_trials: Field::HasMany,
    html_variant_successes: Field::HasMany,
    id: Field::Number,
    group: Field::String,
    name: Field::String,
    html: Field::Text,
    target_tag: Field::String,
    success_rate: Field::Number.with_options(decimals: 2),
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
    user
    html_variant_trials
    html_variant_successes
    id
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    user
    html_variant_trials
    html_variant_successes
    id
    group
    name
    html
    target_tag
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
    user
    html_variant_trials
    html_variant_successes
    group
    name
    html
    target_tag
    success_rate
    published
    approved
  ].freeze

  # Overwrite this method to customize how html variants are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(html_variant)
  #   "HtmlVariant ##{html_variant.id}"
  # end
end
