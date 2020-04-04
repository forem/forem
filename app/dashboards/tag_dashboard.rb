require "administrate/base_dashboard"

class TagDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    supported: Field::Boolean,
    wiki_body_markdown: Field::Text,
    wiki_body_html: Field::Text,
    rules_markdown: Field::Text,
    rules_html: Field::Text,
    short_summary: Field::String,
    requires_approval: Field::Boolean,
    submission_template: Field::Text,
    pretty_name: Field::String,
    profile_image: CarrierwaveField,
    social_image: CarrierwaveField,
    bg_color_hex: Field::String,
    text_color_hex: Field::String,
    keywords_for_search: Field::String,
    taggings_count: Field::Number,
    buffer_profile_id_code: Field::String
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to five items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    name
    supported
    taggings_count
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    supported
    wiki_body_markdown
    wiki_body_html
    rules_markdown
    rules_html
    short_summary
    requires_approval
    submission_template
    pretty_name
    profile_image
    social_image
    bg_color_hex
    text_color_hex
    keywords_for_search
    buffer_profile_id_code
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    supported
    wiki_body_markdown
    rules_markdown
    short_summary
    requires_approval
    submission_template
    pretty_name
    profile_image
    social_image
    bg_color_hex
    text_color_hex
    keywords_for_search
    buffer_profile_id_code
  ].freeze

  # Overwrite this method to customize how tags are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(tag)
  #   "Tag ##{tag.id}"
  # end
end
