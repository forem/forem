class AddSubforemIdToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :subforem_id, :bigint
  end
end
