class AddHiddenByDefaultToBillboardPlacementAreaConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :billboard_placement_area_configs, :hidden_by_default, :boolean, default: false, null: false
  end
end
