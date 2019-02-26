require "administrate/base_dashboard"

class ReactionDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    reactable: Field::Polymorphic,
    user: Field::BelongsTo,
    user_id: UserIdField,
    id: Field::Number,
    category: Field::String,
    points: Field::Number.with_options(decimals: 2),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    reactable
    user
    id
    category
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    reactable
    user
    user_id
    id
    category
    points
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    reactable
    user_id
    category
    points
  ].freeze

  # Overwrite this method to customize how reactions are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(reaction)
    "#{reaction.category} on #{reaction.reactable_type} ##{reaction.reactable_id}"
  end
end
