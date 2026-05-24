class AddCacheExpirySecondsToBillboardPlacementAreaConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :billboard_placement_area_configs, :cache_expiry_seconds, :integer, default: 180, null: false
  end
end
