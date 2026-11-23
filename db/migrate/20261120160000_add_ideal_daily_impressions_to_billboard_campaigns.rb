class AddIdealDailyImpressionsToBillboardCampaigns < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      change_table :billboard_campaigns, bulk: true do |t|
        t.integer :ideal_daily_impressions, default: 0, null: false
        t.float :delivery_throttle_rate, default: 1.0, null: false
      end
    end
  end
end
