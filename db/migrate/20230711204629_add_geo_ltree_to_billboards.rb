class AddGeoLtreeToBillboards < ActiveRecord::Migration[7.0]
  def up
    enable_extension "ltree"

    add_column :display_ads, :geo_ltree, :ltree, array: true
  end

  def down
    safety_assured do
      remove_column :display_ads, :geo_ltree

      disable_extension "ltree"
    end
  end
end
