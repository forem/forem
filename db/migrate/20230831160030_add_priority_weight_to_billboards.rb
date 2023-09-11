class AddPriorityWeightToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :weight, :float, default: 1.0, null: false
  end
end
