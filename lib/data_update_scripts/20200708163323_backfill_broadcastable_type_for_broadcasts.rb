module DataUpdateScripts
  class BackfillBroadcastableTypeForBroadcasts
    def run
      Broadcast.where(broadcastable_type: nil).each do |cast|
        cast.update!(broadcastable_type: broadcast.type_of)
      end
    end
  end
end
