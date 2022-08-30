class AddNameToDisplayAd < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ad, :name, :string
  end
end
