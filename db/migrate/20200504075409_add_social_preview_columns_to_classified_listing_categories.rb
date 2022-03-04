class AddSocialPreviewColumnsToClassifiedListingCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :classified_listing_categories, :social_preview_description, :string
    add_column :classified_listing_categories, :social_preview_color, :string
  end
end
