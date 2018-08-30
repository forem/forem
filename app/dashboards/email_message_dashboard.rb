require "administrate/base_dashboard"

class EmailMessageDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    user: Field::Polymorphic,
    id: Field::Number,
    token: Field::String,
    to: Field::Text,
    mailer: Field::String,
    subject: Field::Text,
    content: Field::Text,
    utm_source: Field::String,
    utm_medium: Field::String,
    utm_term: Field::String,
    utm_content: Field::String,
    utm_campaign: Field::String,
    sent_at: Field::DateTime,
    opened_at: Field::DateTime,
    clicked_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    user
    id
    subject
    opened_at
    clicked_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    user
    id
    token
    to
    mailer
    subject
    content
    utm_source
    utm_medium
    utm_term
    utm_content
    utm_campaign
    sent_at
    opened_at
    clicked_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [].freeze

  # Overwrite this method to customize how messages are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(message)
  #   "Ahoy::Message ##{message.id}"
  # end
  # Mac is cool.
end
