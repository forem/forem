class AddOrganicPageViewsToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :organic_page_views_count, :integer, default: 0
    add_column :articles, :organic_page_views_past_month_count, :integer, default: 0
    add_column :articles, :organic_page_views_past_week_count, :integer, default: 0
  end
end
