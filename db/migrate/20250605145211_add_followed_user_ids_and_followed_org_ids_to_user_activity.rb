class AddFollowedUserIdsAndFollowedOrgIdsToUserActivity < ActiveRecord::Migration[7.0]
  def change
    # Following established patterns, we label followed as alltime and use jsonb
    add_column :user_activities, :alltime_users, :jsonb, default: []
    add_column :user_activities, :alltime_organizations, :jsonb, default: []
  end
end
