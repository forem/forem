module DataUpdateScripts
  class InsertTwitchConnectBroadcast
    def run
      return if Broadcast.find_by title: "Welcome Notification: twitch_connect"

      message = "You're on a roll! 🎉  Do you have a Twitch account? " \
        "Consider <a href='/settings'>connecting it</a>."

      Broadcast.create!(
        title: "Welcome Notification: twitch_connect",
        processed_html: message,
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
