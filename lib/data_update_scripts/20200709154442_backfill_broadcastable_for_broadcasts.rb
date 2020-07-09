module DataUpdateScripts
  class BackfillBroadcastableForBroadcasts
    def run
      Broadcast.find_each do |cast|
        case cast.type_of
        when "Welcome"
          broadcastable = WelcomeNotification.create
          cast.update!(broadcastable: broadcastable)
        when "Announcement"
          broadcastable = Announcement.create(banner_style: cast.banner_style)
          cast.update!(broadcastable: broadcastable)
        end
      end
    end
  end
end
