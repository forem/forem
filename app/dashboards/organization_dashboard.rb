require "administrate/base_dashboard"

class OrganizationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    summary: Field::Text,
    profile_image: CarrierwaveField,
    nav_image: CarrierwaveField,
    url: Field::String,
    twitter_username: Field::String,
    github_username: Field::String,
    jobs_url: Field::String,
    jobs_email: Field::String,
    address: Field::String,
    city: Field::String,
    state: Field::String,
    zip_code: Field::String,
    bg_color_hex: Field::String,
    text_color_hex: Field::String,
    country: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    users: Field::HasMany,
    approved: Field::Boolean,
  }

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :profile_image,
    :name,
    :url,
    :twitter_username,
    :approved,
  ]

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :name,
    :slug,
    :summary,
    :profile_image,
    :nav_image,
    :url,
    :bg_color_hex,
    :text_color_hex,
    :twitter_username,
    :github_username,
    :jobs_url,
    :jobs_email,
    :address,
    :city,
    :state,
    :zip_code,
    :country,
    :approved,
  ]

  def display_resource(organization)
    organization.name
  end
end
