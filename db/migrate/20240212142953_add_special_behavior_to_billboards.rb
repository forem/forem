class AddSpecialBehaviorToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :special_behavior, :integer, default: 0, null: false
  end
end
