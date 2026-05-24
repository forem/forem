class AddIdealDailyPromotedBillboardImpressionsIndexToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :organizations, :ideal_daily_promoted_billboard_impressions,
              name: "idx_orgs_on_ideal_daily_promoted_bb_impressions",
              algorithm: :concurrently
  end
end

