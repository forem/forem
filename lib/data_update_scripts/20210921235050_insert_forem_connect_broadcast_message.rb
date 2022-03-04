module DataUpdateScripts
  class InsertForemConnectBroadcastMessage
    def run
      return if Broadcast.find_by(title: "Welcome Notification: forem_connect")

      Broadcast.create!(
        title: "Welcome Notification: forem_connect",
        processed_html: I18n.t("broadcast.connect.forem"),
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
