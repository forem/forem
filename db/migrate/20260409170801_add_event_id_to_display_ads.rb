class AddEventIdToDisplayAds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  
  def change
    add_reference :display_ads, :event, null: true, index: false
    add_index :display_ads, :event_id, algorithm: :concurrently
  end
end
