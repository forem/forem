class AddMinimizedColumnsToDisplayAds < ActiveRecord::Migration[7.2]
  def change
    add_column :display_ads, :minimized_body_markdown, :text
    add_column :display_ads, :minimized_processed_html, :text
  end
end
