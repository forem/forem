class AddPromotionalBillboardTrackingToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :ideal_daily_promoted_billboard_impressions, :integer, default: 0, null: false
    add_column :organizations, :past_24_hours_promoted_billboard_impressions, :integer, default: 0, null: false
    add_column :organizations, :currently_paused_promotional_billboards, :boolean, default: false, null: false
  end
end

