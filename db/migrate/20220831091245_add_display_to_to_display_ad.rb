class AddDisplayToToDisplayAd < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :display_to, :integer, default: 0, null: false
  end
end
