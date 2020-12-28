module DataUpdateScripts
  class AppendCollectiveNounToCommunityName
    def run
      return "#{SiteConfig.community_name} #{SiteConfig.collective_noun}" unless SiteConfig.collective_noun_disabled?
    end
  end
end
