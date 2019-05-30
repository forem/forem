class RateLimitCheckerJob < ApplicationJob
  queue_as :rate_limit_checker

  def perform(user_id)
    user = User.find_by(id: user_id)
    PingAdmins.call(user) if user
  end
end
