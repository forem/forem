class RemoveUnUsedAttributesFromModels < ActiveRecord::Migration[5.1]
  def change
    remove_column :articles, :boosted
    remove_column :articles, :github_path
    remove_column :articles, :image_jpg_quality
    remove_column :articles, :intro_html
    remove_column :articles, :programming_category
    remove_column :articles, :sponsor_id
    remove_column :articles, :sponsor_showing

    remove_column :comments, :link_id
    remove_column :comments, :article_conversion_inquiry
    remove_column :comments, :article_conversion_lost
    remove_column :comments, :article_conversion_won

  end
end
