module DataUpdateScripts
  class InsertAppleConnectBroadcastMessage
    def run
      title = "Welcome Notification: apple_connect"
      return if Broadcast.find_by title: title

      message = "You're on a roll! 🎉  Do you have an Apple account? " \
                "Consider <a href='/settings'>connecting it</a>."

      Broadcast.create!(
        title: title,
        processed_html: message,
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
