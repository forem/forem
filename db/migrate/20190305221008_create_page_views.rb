class CreatePageViews < ActiveRecord::Migration[5.1]
  def change
    create_table :page_views do |t|
      t.bigint    :user_id
      t.bigint    :article_id
      t.integer   :counts_for_number_of_views, default: 1
      t.integer   :time_tracked_in_seconds, default: 15
      t.string    :referrer
      t.string    :user_agent
      t.timestamps
    end
    add_index :page_views, :user_id
    add_index :page_views, :article_id
  end
end
