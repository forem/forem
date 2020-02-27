module DataUpdateScripts
  class BackfillColumnForBroadcasts
    def run
      Broadcast.find_each { |broadcast| broadcast.update!(active: broadcast.sent) }
    end
  end
end
