class AddFullyCachedToBillboardPlacementAreaConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :billboard_placement_area_configs, :fully_cached, :boolean, default: false, null: false
  end
end
