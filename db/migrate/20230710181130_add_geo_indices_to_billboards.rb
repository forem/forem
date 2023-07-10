class AddGeoIndicesToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :display_ads, :geo_array, using: :gin, algorithm: :concurrently
    add_index :display_ads, :geo_text, using: :gin, opclass: :gin_trgm_ops, algorithm: :concurrently
  end
end
