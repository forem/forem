class AddSemanticCandidateLimitToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :semantic_candidate_limit, :integer, default: 200, null: false
  end
end
