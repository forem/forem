class AddLastBufferedToClassifiedListings < ActiveRecord::Migration[5.2]
  def change
    add_column :classified_listings, :last_buffered, :datetime
  end
end
