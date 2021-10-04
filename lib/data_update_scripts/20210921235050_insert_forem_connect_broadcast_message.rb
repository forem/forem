module DataUpdateScripts
  class InsertForemConnectBroadcastMessage
    def run
      return if Broadcast.find_by(title: "Welcome Notification: forem_connect")

      message = "You're on a roll! 🎉  Do you have a Forem account? " \
                "Consider <a href='/settings'>connecting it</a>."

      Broadcast.create!(
        title: "Welcome Notification: forem_connect",
        processed_html: message,
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
