module DataUpdateScripts
  class AppendCommunityToCommunityName
    def run
      return unless SiteConfig.collective_noun_disabled.false?

      SiteConfig.where(var: "community_name").find_each do |community_name|
        community_name.update!(value: "#{community_name.value} #{SiteConfig.collective_noun}")
      end
    end
  end
end
