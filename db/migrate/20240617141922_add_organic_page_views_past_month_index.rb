class AddOrganicPageViewsPastMonthIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :articles, :organic_page_views_past_month_count, algorithm: :concurrently
  end
end
