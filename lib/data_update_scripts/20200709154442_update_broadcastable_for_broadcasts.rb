module DataUpdateScripts
  class UpdateBroadcastableForBroadcasts
    def run
      Broadcast.find_each do |cast|
        case cast.broadcastable_type
        when "Welcome"
          broadcastable = WelcomeNotification.create
          result = cast.update(broadcastable: broadcastable)
          next if result

          Honeybadger.context(broadcast_id: cast.id, errors: cast.errors_as_sentence)
          Honeybadger.notify("Broadcast Update Failed")
        when "Announcement"
          broadcastable = Announcement.create(banner_style: cast.banner_style)
          cast.update!(broadcastable: broadcastable)
        end
      end
    end
  end
end
