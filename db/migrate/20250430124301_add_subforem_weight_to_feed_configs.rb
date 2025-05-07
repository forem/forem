class AddSubforemWeightToFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :feed_configs, :recent_subforem_weight, :float, default: 0.0, null: false
  end
end
