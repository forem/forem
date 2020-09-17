class RemoveCategoryFromClassifiedListing < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :classified_listings, :category }
  end
end
