class AddIndexToPageViewDomain < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :page_views, :domain, algorithm: :concurrently
  end
end
