module DataUpdateScripts
  class UpdateUserUpdateRateLimitDefault
    def run
      return if Settings::RateLimit.user_update > 5

      Settings::RateLimit.user_update = 15
    end
  end
end
