class RemoveUniqueIndexOnPagesSlug < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    remove_index :pages, name: "index_pages_on_slug", algorithm: :concurrently
  end
end
