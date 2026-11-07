module DataUpdateScripts
  class AddOrganizationArticleAnalyticsFeatureFlag
    def run
      FeatureFlag.add(:org_article_analytics)
    end
  end
end
