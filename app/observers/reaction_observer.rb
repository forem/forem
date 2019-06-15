class ReactionObserver < ActiveRecord::Observer
  def after_create(reaction)
    if reaction.category == "vomit"
      SlackBotPingJob.perfom_later(
        message: "#{reaction.user.name} (https://dev.to#{reaction.user.path}) \nreacted with a #{reaction.category} on\nhttps://dev.to#{reaction.reactable.path}",
        channel: "abuse-reports",
        username: "abuse_bot",
        icon_emoji: ":cry:",
      )
    end
  rescue StandardError => e
    Rails.logger.error("observer error: #{e}")
  end
end
