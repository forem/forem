class AddPreferPairedWithToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :prefer_paired_with_billboard_id, :bigint
  end
end
