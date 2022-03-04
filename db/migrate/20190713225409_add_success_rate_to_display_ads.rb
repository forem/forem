class AddSuccessRateToDisplayAds < ActiveRecord::Migration[5.2]
  def change
    add_column :display_ads, :success_rate, :float, default: 0.0
  end
end
