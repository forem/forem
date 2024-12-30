class AddSubforemIdIndexToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!  

  def change
    add_index :articles, :subforem_id, algorithm: :concurrently
  end
end
