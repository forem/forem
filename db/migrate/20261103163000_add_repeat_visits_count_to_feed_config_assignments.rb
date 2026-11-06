class AddRepeatVisitsCountToFeedConfigAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_config_assignments, :repeat_visits_count, :integer, default: 0, null: false
  end
end
