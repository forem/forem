class OriginallyPublishedAtForListing < ActiveRecord::Migration[6.0]
  def change
    add_column :classified_listings, :originally_published_at, :datetime
  end
end
