class AddIndicesToDisplayAdTargetGeolocations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # GiST index enables custom ltree operators
    add_index :display_ads,
              :target_geolocations,
              using: :gist,
              name: "gist_index_display_ads_on_target_geolocations",
              algorithm: :concurrently
  end
end
