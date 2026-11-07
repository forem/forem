module DataUpdateScripts
  class AddOrganizationCommunityDiscoveryFeatureFlag
    def run
      FeatureFlag.add(:org_community_discovery)
    end
  end
end
