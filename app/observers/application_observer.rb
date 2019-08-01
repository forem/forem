class ApplicationObserver < ActiveRecord::Observer
  def warned_user_ping(activity)
    return unless activity.user.warned == true

    SlackBotPingJob.perform_later message: "Activity: https://dev.to#{activity.path}\nManage @#{activity.user.username}: https://dev.to/internal/users/#{activity.user.id}",
                                  channel: "warned-user-comments",
                                  username: "sloan_watch_bot",
                                  icon_emoji: ":sloan:"
  end
end
