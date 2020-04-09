class AddListingCategoryToClassifiedListing < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_reference :classified_listings,
                  :classified_listing_category,
                  index: { algorithm: :concurrently }
  end
end
