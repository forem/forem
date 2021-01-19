module DataUpdateScripts
  class UpdateUserUpdateRateLimitDefault
    def run
      return if SiteConfig.rate_limit_user_update > 5

      SiteConfig.rate_limit_user_update = 15
    end
  end
end
