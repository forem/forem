class AddEventIdToDisplayAds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  
  def up
    add_reference :display_ads, :event, null: true, index: false
    add_index :display_ads, :event_id, algorithm: :concurrently, if_not_exists: true
    add_foreign_key :display_ads, :events, validate: false
  end

  def down
    remove_foreign_key :display_ads, :events, if_exists: true
    remove_index :display_ads, :event_id, algorithm: :concurrently, if_exists: true
    safety_assured { remove_reference :display_ads, :event, null: true, index: false }
  end
end
