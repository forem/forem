class AddIndexToDisplayAdsBillboardCampaignId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :display_ads, name: "index_display_ads_on_billboard_campaign_id", if_exists: true,
                                 algorithm: :concurrently
      add_index :display_ads, :billboard_campaign_id, algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :display_ads, name: "index_display_ads_on_billboard_campaign_id", if_exists: true,
                                 algorithm: :concurrently
    end
  end
end
