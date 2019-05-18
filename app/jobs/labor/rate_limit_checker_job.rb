module Labor
  class RateLimitCheckerJob < ApplicationJob
    queue_as :labor_rate_limit_checker

    def perform(user_id)
      user = User.find_by(id: user_id)
      Labor::PingAdminsService.call(user) if user
    end
  end
end
