module DataUpdateScripts
  class BackfillColumnForBroadcasts
    def run
      return unless Broadcast.column_names.include?("sent")

      Broadcast.find_each { |broadcast| broadcast.update!(active: broadcast.sent) }
    end
  end
end
