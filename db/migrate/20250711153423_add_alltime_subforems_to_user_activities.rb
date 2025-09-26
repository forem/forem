class AddAlltimeSubforemsToUserActivities < ActiveRecord::Migration[7.0]
  def change
    # Add alltime_subforems to user_activities
    add_column :user_activities, :alltime_subforems, :jsonb, default: []
  end
end
