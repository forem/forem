# TODO: remove this when Sidekiq has exhausted RateLimitCheckerWorker jobs
class PingAdmins
  def initialize(user, action = "unknown")
    @user = user
    @action = action
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    return unless user

    SlackBot.ping(
      "Rate limit exceeded (#{action}). https://dev.to#{user.path}",
      channel: "abuse-reports",
      username: "rate_limit",
      icon_emoji: ":hand:",
    )
  end

  private

  attr_reader :user, :action
end
