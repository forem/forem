class AddNameToDisplayAd < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :name, :string
  end
end
