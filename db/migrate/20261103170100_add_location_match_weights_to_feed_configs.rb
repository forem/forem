class AddLocationMatchWeightsToFeedConfigs < ActiveRecord::Migration[7.2]
  def change
    change_table :feed_configs, bulk: true do |t|
      t.float :country_match_weight, default: 0.0, null: false
      t.float :region_match_weight, default: 0.0, null: false
    end
  end
end
