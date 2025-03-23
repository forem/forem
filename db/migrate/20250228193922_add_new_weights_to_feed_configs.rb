class AddNewWeightsToFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :feed_configs, :featured_weight, :float, default: 0.0, null: false
    add_column :feed_configs, :clickbait_score_weight, :float, default: 0.0, null: false
    add_column :feed_configs, :compellingness_score_weight, :float, default: 0.0, null: false
    add_column :feed_configs, :randomness_weight, :float, default: 0.0, null: false
  end
end
