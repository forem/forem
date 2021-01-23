module DataUpdateScripts
  class InsertDiscordConnectBroadcast
    def run
      return if Broadcast.find_by title: "Welcome Notification: discord_connect"

      message = "You're on a roll! 🎉  Do you have a Discord account? " \
        "Consider <a href='/settings'>connecting it</a>."

      Broadcast.create!(
        title: "Welcome Notification: discord_connect",
        processed_html: message,
        type_of: "Welcome",
        active: true,
      )
    end
  end
end
