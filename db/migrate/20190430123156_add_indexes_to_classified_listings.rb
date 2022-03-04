class AddIndexesToClassifiedListings < ActiveRecord::Migration[5.2]
  def change
    add_index :classified_listings, :user_id
    add_index :classified_listings, :organization_id
  end
end
