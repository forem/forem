class AddViewableAndRegionToPageViews < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :page_views, :viewable, polymorphic: true, null: true, index: false
    add_column :page_views, :region, :string
    add_index :page_views, [:viewable_type, :viewable_id], algorithm: :concurrently
  end
end
