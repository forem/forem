class AddMissingForeignKeysToDisplayAdEvents < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :display_ad_events, :display_ads, column: :display_ad_id, on_delete: :cascade, validate: false
    add_foreign_key :display_ad_events, :users, column: :user_id, on_delete: :cascade, validate: false
  end
end
