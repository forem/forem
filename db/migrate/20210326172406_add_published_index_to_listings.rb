class AddPublishedIndexToListings < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    unless index_exists?(:classified_listings, :published)
      add_index :classified_listings, :published, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:classified_listings, :published)
      remove_index :classified_listings, column: :published, algorithm: :concurrently
    end
  end
end
