class AddTargetGeolocationsToDisplayAds < ActiveRecord::Migration[7.0]
  def up
    enable_extension "ltree"

    add_column :display_ads, :target_geolocations, :ltree, array: true, default: []
  end

  def down
    safety_assured do
      remove_column :display_ads, :target_geolocations

      disable_extension "ltree"
    end
  end
end
