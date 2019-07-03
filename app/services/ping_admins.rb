class PingAdmins
  def initialize(user)
    @user = user
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    return unless user && Rails.env.production?

    SlackBot.ping(
      "Rate limit exceeded. https://dev.to#{user.path}",
      channel: "abuse-reports",
      username: "rate_limit",
      icon_emoji: ":hand:",
    )
  end

  private

  attr_reader :user
end
