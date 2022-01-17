module DataUpdateScripts
  class InsertGoogleOuauth2ConnectBroadcastMessage
    def run
      return if Broadcast.find_by(title: "Welcome Notification: google_oauth2_connect")

      message = "You're on a roll! 🎉  Do you have a Google account? " \
                "Consider <a href='/settings'>connecting it</a>."

      Broadcast.create!(
        title: "Welcome Notification: google_oauth2_connect",
        processed_html: message,
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
