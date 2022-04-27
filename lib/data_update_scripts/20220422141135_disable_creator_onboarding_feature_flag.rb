module DataUpdateScripts
  class DisableCreatorOnboardingFeatureFlag
    def run
      FeatureFlag.disable(:creator_onboarding)
    end
  end
end
