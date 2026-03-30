class AddBrinIndexToDisplayAdEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :display_ad_events, 
              :created_at, 
              using: :brin, 
              algorithm: :concurrently,
              name: "index_display_ad_events_on_created_at_brin"
  end
end
