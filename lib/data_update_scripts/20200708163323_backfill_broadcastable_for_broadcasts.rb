module DataUpdateScripts
  class BackfillBroadcastableForBroadcasts
    def run
      Broadcast.where(broadcastable_type: nil).find_each do |cast|
        cast.update!(broadcastable_type: cast.type_of)
      end
    end
  end
end
