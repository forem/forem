class ValidateBillboardCampaignIdOnDisplayAds < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :display_ads, :billboard_campaigns
  end
end
