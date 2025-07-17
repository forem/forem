class AddSubforemWeightsAndMoreToFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    # Add subforem weights to feed_configs
    add_column :feed_configs, :subforem_follow_weight, :float, default: 0.0, null: false
  end
end
