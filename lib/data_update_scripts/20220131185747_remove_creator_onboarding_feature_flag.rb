module DataUpdateScripts
  class RemoveCreatorOnboardingFeatureFlag
    def run
      FeatureFlag.remove(:creator_onboarding)
    end
  end
end
