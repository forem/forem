class AddDeliveryCapsToDisplayAds < ActiveRecord::Migration[8.0]
  def up
    # Nullable and constant-default columns are metadata-only changes on PostgreSQL 11+.
    safety_assured do
      change_table :display_ads, bulk: true do |t|
        t.integer :max_impressions_count, null: false, default: 0
        t.integer :max_clicks_count, null: false, default: 0
        t.bigint :billboard_campaign_id
      end
    end
    add_foreign_key :display_ads, :billboard_campaigns, on_delete: :nullify, validate: false
  end

  def down
    safety_assured do
      remove_foreign_key :display_ads, :billboard_campaigns
      change_table :display_ads, bulk: true do |t|
        t.remove :billboard_campaign_id, :max_clicks_count, :max_impressions_count
      end
    end
  end
end
