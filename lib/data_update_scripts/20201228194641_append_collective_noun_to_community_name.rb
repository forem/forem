module DataUpdateScripts
  class AppendCollectiveNounToCommunityName
    def run
      return if SiteConfig.collective_noun_disabled

      SiteConfig.community_name = "#{SiteConfig.community_name} #{SiteConfig.collective_noun}"
    end
  end
end
