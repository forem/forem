class AddArchivedToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :archived, :boolean, default: false
  end
end
