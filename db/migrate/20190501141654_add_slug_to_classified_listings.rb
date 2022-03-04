class AddSlugToClassifiedListings < ActiveRecord::Migration[5.2]
  def change
    add_column :classified_listings, :slug, :string
  end
end
