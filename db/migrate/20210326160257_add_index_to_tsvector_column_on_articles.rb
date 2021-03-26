class AddIndexToTsvectorColumnOnArticles < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :articles, :tsv, using: "gin", algorithm: :concurrently
  end
end
