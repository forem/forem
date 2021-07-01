module DataUpdateScripts
  class InsertFacebookConnectBroadcastMessage
    def run
      return if Broadcast.find_by title: "Welcome Notification: facebook_connect"

      message = "You're on a roll! 🎉  Do you have a Facebook account? " \
                "Consider <a href='/settings'>connecting it</a>."

      Broadcast.create!(
        title: "Welcome Notification: facebook_connect",
        processed_html: message,
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
