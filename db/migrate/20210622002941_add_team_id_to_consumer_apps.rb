class AddTeamIdToConsumerApps < ActiveRecord::Migration[6.1]
  def change
    add_column :consumer_apps, :team_id, :string
  end
end
