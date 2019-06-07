class ApplicationObserver < ActiveRecord::Observer
  def warned_user_ping(activity)
    return unless activity.user.warned == true

    SlackBot.delay.ping "Activity: https://dev.to/#{activity.path}\nManage @#{activity.user.username}: https://dev.to/internal/users/#{activity.user.id}",
                        channel: "warned-user-activity",
                        username: "sloan_watch_bot",
                        icon_emoji: ":sloan:"
  end
end
