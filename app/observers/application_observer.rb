class ApplicationObserver < ActiveRecord::Observer
  def warned_user_ping(activity)
    return unless activity.user.warned == true

    SlackBot.delay.ping "@#{activity.user.username} just posted.\nManage User- https://dev.to/internal/users/#{activity.user.id}\nPost- https://dev.to#{activity.path}",
                        channel: "warned-user-activity",
                        username: "sloan_watch_bot",
                        icon_emoji: ":sloan:"
  end
end
