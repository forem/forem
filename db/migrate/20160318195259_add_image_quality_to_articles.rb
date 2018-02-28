class AddImageQualityToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :image_jpg_quality, :integer, default: 90
  end
end
