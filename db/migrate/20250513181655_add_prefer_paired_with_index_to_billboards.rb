class AddPreferPairedWithIndexToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :display_ads, :prefer_paired_with_billboard_id, algorithm: :concurrently
  end
end
