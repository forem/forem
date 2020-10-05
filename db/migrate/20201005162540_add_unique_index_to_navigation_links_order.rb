class AddUniqueIndexToNavigationLinksOrder < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :navigation_links, :order, unique: true, algorithm: :concurrently
  end
end
