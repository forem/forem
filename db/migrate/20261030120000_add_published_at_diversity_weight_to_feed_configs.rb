class AddPublishedAtDiversityWeightToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :published_at_diversity_weight, :float, default: 0.0, null: false
  end
end
