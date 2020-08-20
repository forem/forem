class ListingCategory < ApplicationRecord
  # We used to use both "classified listing" and "listing" throughout the app.
  # We standardized on the latter, but keeping the table name was easier.
  self.table_name = "classified_listing_categories"

  has_many :listings, inverse_of: :listing_category,
                      foreign_key: :classified_listing_category_id,
                      dependent: :restrict_with_error

  before_validation :normalize_social_preview_color

  validates :name, :cost, :rules, :slug, presence: true
  validates :name, :slug, uniqueness: true

  # This needs to be a hex color of format "#CCC" or "#A1B2C3"
  validates :social_preview_color,
            format: /\A#(?:[a-f0-9]{3}){1,2}\z/,
            allow_blank: true

  private

  def normalize_social_preview_color
    return unless social_preview_color

    self.social_preview_color = social_preview_color.downcase
  end
end
