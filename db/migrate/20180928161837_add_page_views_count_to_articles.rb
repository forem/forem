class AddPageViewsCountToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :page_views_count, :integer, default: 0
    add_column :articles, :previous_positive_reactions_count, :integer, default: 0
  end
end
