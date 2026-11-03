class AddRegionToArticles < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :region, :string
  end
end
