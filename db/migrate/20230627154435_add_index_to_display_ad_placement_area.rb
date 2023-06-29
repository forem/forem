class AddIndexToDisplayAdPlacementArea < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :display_ads, :placement_area, algorithm: :concurrently
  end
end
