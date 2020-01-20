class ReactionObserver < ActiveRecord::Observer
  def after_create(reaction)
    if reaction.category == "vomit"
      SlackBotPingWorker.perfom_async(
        "#{reaction.user.name} (https://dev.to#{reaction.user.path}) \nreacted with a #{reaction.category} on\nhttps://dev.to#{reaction.reactable.path}", # message
        "abuse-reports", # channel
        "abuse_bot", # username
        ":cry:", # icon_emoji
      )
    end
  rescue StandardError => e
    Rails.logger.error("observer error: #{e}")
  end
end
