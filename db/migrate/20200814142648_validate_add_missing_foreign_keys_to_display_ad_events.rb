class ValidateAddMissingForeignKeysToDisplayAdEvents < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :display_ad_events, :display_ads
    validate_foreign_key :display_ad_events, :users
  end
end
