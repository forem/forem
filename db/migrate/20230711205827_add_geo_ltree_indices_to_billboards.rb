class AddGeoLtreeIndicesToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :display_ads, :geo_ltree, algorithm: :concurrently

    add_index :display_ads,
              :geo_ltree,
              using: :gist,
              name: "gist_index_display_ads_on_geo_ltree",
              algorithm: :concurrently
  end
end
