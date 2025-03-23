class AddTypeOfToIndexArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :articles, :type_of, algorithm: :concurrently
  end
end
