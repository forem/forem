class RemoveUnusedColumnsFromDisplayAds < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :display_ads, :cost_per_click, :float, default: 0.0
      remove_column :display_ads, :cost_per_impression, :float, default: 0.0
    end
  end
end
