class ApplicationObserver < ActiveRecord::Observer
  def warned_user_ping(activity)
    if activity.user.warned == true
      SlackBot.delay.ping "@#{activity.user.username} just posted.\nThey've been warned since #{activity.user.roles.where(name: 'warned')[0].updated_at.strftime('%d %B %Y')}\nhttps://dev.to#{activity.path}",
              channel: "warned-user-activity",
              username: "sloan_watch_bot",
              icon_emoji: ":sloan:"
    end
  end
end
