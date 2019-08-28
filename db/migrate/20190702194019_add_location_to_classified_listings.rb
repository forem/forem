class AddLocationToClassifiedListings < ActiveRecord::Migration[5.2]
  def change
    add_column :classified_listings, :location, :string
  end
end
