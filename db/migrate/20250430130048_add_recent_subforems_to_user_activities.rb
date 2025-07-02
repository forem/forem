class AddRecentSubforemsToUserActivities < ActiveRecord::Migration[7.0]
  def change
    add_column :user_activities, :recent_subforems, :jsonb, default: []
  end
end
