class AddIdealDailyImpressionsIndexToBillboardCampaigns < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "idx_billboard_campaigns_on_ideal_daily_impressions".freeze

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :billboard_campaigns, name: INDEX_NAME, if_exists: true, algorithm: :concurrently
      add_index :billboard_campaigns, :ideal_daily_impressions,
                where: "ideal_daily_impressions > 0",
                name: INDEX_NAME,
                algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :billboard_campaigns, name: INDEX_NAME, if_exists: true, algorithm: :concurrently
    end
  end
end
