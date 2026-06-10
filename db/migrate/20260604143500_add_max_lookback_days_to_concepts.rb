class AddMaxLookbackDaysToConcepts < ActiveRecord::Migration[7.0]
  def change
    add_column :concepts, :max_lookback_days, :integer, default: 0, null: false
  end
end
