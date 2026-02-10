class AddSemanticMatchWeightToFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :feed_configs, :semantic_match_weight, :float, default: 0.0
  end
end
