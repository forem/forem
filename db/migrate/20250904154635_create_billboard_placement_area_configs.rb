class CreateBillboardPlacementAreaConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :billboard_placement_area_configs do |t|
      t.string :placement_area, null: false
      t.integer :signed_in_rate, null: false, default: 100
      t.integer :signed_out_rate, null: false, default: 100

      t.timestamps
    end
    add_index :billboard_placement_area_configs, :placement_area, unique: true
  end
end
