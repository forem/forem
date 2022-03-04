module DataUpdateScripts
  class EnableCreatorOnboardingFeatureFlag
    def run
      FeatureFlag.add(:creator_onboarding)
      FeatureFlag.enable(:creator_onboarding)
    end
  end
end
