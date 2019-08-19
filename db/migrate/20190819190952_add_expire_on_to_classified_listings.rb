class AddExpireOnToClassifiedListings < ActiveRecord::Migration[5.2]
  def change
    add_column :classified_listings, :expire_on, :datetime
  end
end
