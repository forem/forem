class AddFeedAiPreferenceToUsersSettingsAndFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :users_settings, :feed_ai_preference, :integer, default: 0, null: false
    add_column :feed_configs, :ai_disclosure_matching_weight, :float, default: 0.0, null: false
    add_column :feed_configs, :autonomous_ai_penalty_weight, :float, default: 0.0, null: false
  end
end
