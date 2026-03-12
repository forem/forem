module DataUpdateScripts
  class AddOrgPremiumFeatureFlags
    def run
      FeatureFlag.add(:org_readme)
      FeatureFlag.add(:org_lead_forms)
    end
  end
end
