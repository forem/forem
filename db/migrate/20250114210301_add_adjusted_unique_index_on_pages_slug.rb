class AddAdjustedUniqueIndexOnPagesSlug < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :pages, [:slug, :subforem_id], unique: true, name: "index_pages_on_slug_and_subforem_id", algorithm: :concurrently
  end
end
