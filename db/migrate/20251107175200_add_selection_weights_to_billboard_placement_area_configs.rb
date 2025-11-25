class AddSelectionWeightsToBillboardPlacementAreaConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :billboard_placement_area_configs, :selection_weights, :jsonb, default: {}, null: false
  end
end
