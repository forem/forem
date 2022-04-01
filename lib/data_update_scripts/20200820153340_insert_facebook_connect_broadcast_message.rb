module DataUpdateScripts
  class InsertFacebookConnectBroadcastMessage
    def run
      return if Broadcast.find_by title: "Welcome Notification: facebook_connect"

      Broadcast.create!(
        title: "Welcome Notification: facebook_connect",
        processed_html: I18n.t("broadcast.connect.facebook"),
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
