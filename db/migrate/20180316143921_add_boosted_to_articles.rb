class AddBoostedToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :boosted, :boolean, default: false
  end
end
