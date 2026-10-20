class AddFavoritedWeightToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :favorited_weight, :float, default: 0.0, null: false
  end
end
