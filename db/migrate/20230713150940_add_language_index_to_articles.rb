class AddLanguageIndexToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :articles, :language, algorithm: :concurrently
  end
end
