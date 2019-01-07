require "administrate/base_dashboard"

class CommentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    commentable: Field::Polymorphic,
    user: Field::BelongsTo,
    user_id: UserIdField,
    reactions: Field::HasMany,
    id: Field::Number,
    body_markdown: Field::Text.with_options(searchable: true),
    body_html: Field::Text,
    edited: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    ancestry: Field::String,
    id_code: Field::String,
    score: Field::Number,
    deleted: Field::Boolean
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    user
    body_markdown
    reactions
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    commentable
    user
    reactions
    id
    body_markdown
    edited
    created_at
    updated_at
    ancestry
    id_code
    score
    deleted
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    user_id
    body_markdown
    score
    deleted
  ].freeze

  # Overwrite this method to customize how comments are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(comment)
    "Comment ##{comment.id} - #{comment.title}"
  end
end
