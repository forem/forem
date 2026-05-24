class AddCurrentlyPausedPromotionalBillboardsIndexToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :organizations, :currently_paused_promotional_billboards,
              name: "idx_orgs_on_currently_paused_promo_billboards",
              algorithm: :concurrently
  end
end

