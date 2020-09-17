class AddUniqueIndexToHtmlVariantsName < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :html_variants, :name, unique: true, algorithm: :concurrently
  end
end
