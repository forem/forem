class AddOrganizationIdIndexToDisplayAds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :display_ads, :organization_id,
              name: "index_display_ads_on_organization_id",
              algorithm: :concurrently
  end
end

