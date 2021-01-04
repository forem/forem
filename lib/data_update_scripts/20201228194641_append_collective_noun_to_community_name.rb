module DataUpdateScripts
  class AppendCollectiveNounToCommunityName
    def run
      return unless SiteConfig.respond_to?(:collective_noun_disabled)
      return unless SiteConfig.collective_noun_disabled? || SiteConfig.collective_noun.blank?

      SiteConfig.community_name = "#{SiteConfig.community_name} #{SiteConfig.collective_noun}"
    end
  end
end
