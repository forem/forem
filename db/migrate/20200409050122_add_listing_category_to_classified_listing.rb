class AddListingCategoryToClassifiedListing < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_reference :classified_listings,
                    :classified_listing_category,
                    foreign_key: true,
                    index: { algorithm: :concurrently }
    end
  end
end
