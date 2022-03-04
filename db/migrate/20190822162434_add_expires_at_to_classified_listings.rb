class AddExpiresAtToClassifiedListings < ActiveRecord::Migration[5.2]
  def change
    add_column :classified_listings, :expires_at, :datetime
  end
end
