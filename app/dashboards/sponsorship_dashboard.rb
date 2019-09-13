require "administrate/base_dashboard"

class SponsorshipDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    user: Field::BelongsTo,
    user_id: UserIdField,
    organization: Field::BelongsTo,
    organization_id: Field::Number,
    id: Field::Number,
    level: Field::String,
    status: Field::String,
    expires_at: Field::DateTime,
    blurb_html: Field::Text,
    featured_number: Field::Number,
    instructions: Field::Text,
    instructions_updated_at: Field::DateTime,
    tagline: Field::String,
    url: Field::String,
    sponsorable_id: Field::Number,
    sponsorable_type: Field::String,
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
    organization
    id
    level
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    user
    organization
    id
    level
    status
    expires_at
    blurb_html
    featured_number
    instructions
    instructions_updated_at
    tagline
    url
    sponsorable_id
    sponsorable_type
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    user_id
    organization_id
    level
    status
    expires_at
    blurb_html
    featured_number
    instructions
    instructions_updated_at
    tagline
    url
    sponsorable_id
    sponsorable_type
  ].freeze

  # Overwrite this method to customize how sponsorships are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(sponsorship)
  #   "Sponsorship ##{sponsorship.id}"
  # end
end
