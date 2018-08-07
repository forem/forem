class ReactionObserver < ActiveRecord::Observer
  def after_create(reaction)
    if reaction.points.negative?
      emoji = reaction.category == "thumbsdown" ? ":thumbsdown:" : ":cry:"
      SlackBot.delay.ping(
        "#{reaction.user.name} (https://dev.to#{reaction.user.path}) \nreacted with a #{reaction.category} on\nhttps://dev.to#{reaction.reactable.path}",
        channel: "abuse-reports",
        username: "abuse_bot",
        icon_emoji: emoji,
      )
    end
  rescue StandardError
    puts "observer error"
  end
end
