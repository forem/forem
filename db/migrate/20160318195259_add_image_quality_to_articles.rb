class AddImageQualityToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :image_jpg_quality, :integer, default: 90
  end
end
