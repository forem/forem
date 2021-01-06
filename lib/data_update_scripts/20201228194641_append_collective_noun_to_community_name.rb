module DataUpdateScripts
  class AppendCollectiveNounToCommunityName
    def run
      return if SiteConfig.collective_noun_disabled || SiteConfig.collective_noun.blank?

      SiteConfig.community_name = "#{SiteConfig.community_name} #{SiteConfig.collective_noun}"
    end
  end
end
