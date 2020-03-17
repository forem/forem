class ReactionObserver < ActiveRecord::Observer
  def after_create(reaction)
    if reaction.category == "vomit"
      reactable = reaction.reactable
      user = reaction.user
      url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"

      message = <<~MESSAGE.chomp
        #{user.name} (#{url}#{user.path})
        reacted with a #{reaction.category} on
        #{url}#{reactable.path}
      MESSAGE

      SlackBotPingWorker.perform_async(
        message: message,
        channel: "abuse-reports",
        username: "abuse_bot",
        icon_emoji: ":cry:",
      )
    end
  rescue StandardError => e
    Rails.logger.error("observer error: #{e}")
  end
end
