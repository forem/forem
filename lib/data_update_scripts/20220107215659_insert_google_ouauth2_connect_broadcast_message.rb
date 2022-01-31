module DataUpdateScripts
  class InsertGoogleOuauth2ConnectBroadcastMessage
    def run
      return if Broadcast.find_by(title: "Welcome Notification: google_oauth2_connect")

      Broadcast.create!(
        title: "Welcome Notification: google_oauth2_connect",
        processed_html: I18n.t("broadcast.connect.google"),
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
