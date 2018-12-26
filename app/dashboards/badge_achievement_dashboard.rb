require "administrate/base_dashboard"

class BadgeAchievementDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    user: Field::BelongsTo,
    user_id: UserIdField,
    badge: Field::BelongsTo,
    rewarder: Field::BelongsTo.with_options(class_name: "User"),
    rewarding_context_message_markdown: Field::String,
    rewarding_context_message: Field::String,
    id: Field::Number,
    rewarder_id: UserIdField,
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
    badge
    rewarder
    id
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    badge
    rewarding_context_message
    rewarder
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    user_id
    rewarding_context_message_markdown
    badge
    rewarder_id
  ].freeze

  # Overwrite this method to customize how badge achievements are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(badge_achievement)
  #   "BadgeAchievement ##{badge_achievement.id}"
  # end
end
