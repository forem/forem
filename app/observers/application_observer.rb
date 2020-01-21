class ApplicationObserver < ActiveRecord::Observer
  def warned_user_ping(activity)
    return unless activity.user.warned == true

    SlackBotPingWorker.perform_async(
      message: message(activity),
      channel: "warned-user-comments",
      username: "sloan_watch_bot",
      icon_emoji: ":sloan:",
    )
  end

  def message(activity)
    <<~HEREDOC
      Activity: https://dev.to#{activity.path}
      #{'Comment text: ' + activity.body_markdown.truncate(300) if activity.class.name == 'Comment'}
      ---
      Manage commenter - @#{activity.user.username}: https://dev.to/internal/users/#{activity.user.id},
    HEREDOC
  end
end
