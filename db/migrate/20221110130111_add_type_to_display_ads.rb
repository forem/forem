class AddTypeToDisplayAds < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :type_of, :integer, default: 0, null: false
  end
end
