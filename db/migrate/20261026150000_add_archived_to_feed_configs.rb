class AddArchivedToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :archived, :boolean, default: false, null: false
  end
end
