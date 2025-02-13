class AddSubforemIdIndexToBillboardsAndPages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :navigation_links, :subforem_id, algorithm: :concurrently
    add_index :display_ads, :include_subforem_ids, using: 'gin', algorithm: :concurrently
    add_index :pages, :subforem_id, algorithm: :concurrently
  end
end
