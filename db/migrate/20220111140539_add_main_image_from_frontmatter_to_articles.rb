class AddMainImageFromFrontmatterToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :main_image_from_frontmatter, :boolean, default: false
  end
end
