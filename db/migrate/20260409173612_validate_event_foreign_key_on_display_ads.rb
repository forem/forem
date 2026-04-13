class ValidateEventForeignKeyOnDisplayAds < ActiveRecord::Migration[7.0]
  def change
    validate_check_constraint :events, name: "events_broadcast_config_null"
    validate_foreign_key :display_ads, :events
  end
end
