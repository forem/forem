class AddSecondsVisibleToDisplayAds < ActiveRecord::Migration[7.2]
  def change
    add_column :display_ads, :seconds_visible, :integer, default: 0, null: false
  end
end
