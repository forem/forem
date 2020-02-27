class BackfillColumnForBroadcasts < ActiveRecord::DataMigration
  def up
    Broadcast.find_each { |broadcast| broadcast.update!(active: broadcast.sent) }
  end
end
