require "administrate/base_dashboard"

class ProMembershipDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    user: Field::BelongsTo,
    id: Field::Number,
    status: Field::String,
    expires_at: Field::DateTime,
    expiration_notification_at: Field::DateTime,
    expiration_notifications_count: Field::Number,
    auto_recharge: Field::Boolean,
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
    id
    status
    expires_at
    auto_recharge
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    user
    id
    status
    expires_at
    expiration_notification_at
    expiration_notifications_count
    auto_recharge
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    user
    status
    expires_at
    expiration_notification_at
    expiration_notifications_count
    auto_recharge
  ].freeze

  # Overwrite this method to customize how pro memberships are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(pro_membership)
  #   "ProMembership ##{pro_membership.id}"
  # end
end
