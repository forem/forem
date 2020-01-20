class AddVisitedPathToPageviews < ActiveRecord::Migration[5.2]
  def change
    add_column :page_views, :visited_page_path,     :string
    add_column :page_views, :visited_page_full_url, :string
    add_column :page_views, :visited_page_category, :string
  end
end
