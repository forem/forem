class AddRegularUserWeightsToFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :feed_configs, :recent_page_views_shuffle_weight, :float, default: 0.0, null: false
    add_column :feed_configs, :general_past_day_bonus_weight, :float, default: 0.0, null: false
    add_column :feed_configs, :recently_active_past_day_bonus_weight, :float, default: 0.0, null: false
  end
end
