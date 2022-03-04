class AddIndexToArticlesPath < ActiveRecord::Migration[5.1]
  def change
    add_index :articles, :path
  end
end
