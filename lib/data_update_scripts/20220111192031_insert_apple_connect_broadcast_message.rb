module DataUpdateScripts
  class InsertAppleConnectBroadcastMessage
    def run
      title = "Welcome Notification: apple_connect"
      return if Broadcast.find_by title: title

      Broadcast.create!(
        title: title,
        processed_html: I18n.t("broadcast.connect.apple"),
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
