module DataUpdateScripts
  class AddOrganizationRelatedArticlesFeatureFlag
    def run
      FeatureFlag.add(:org_related_articles)
    end
  end
end
