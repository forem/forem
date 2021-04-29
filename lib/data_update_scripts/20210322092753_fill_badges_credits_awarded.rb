module DataUpdateScripts
  class FillBadgesCreditsAwarded
    def run
      return unless Settings::General.dev_to?

      Badge.update_all("credits_awarded = 5")
    end
  end
end
