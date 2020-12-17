module DataUpdateScripts
  class AppendCommunityToCommunityName
    def run
      SiteConfig.where(var: "community_name").find_each do |community_name|
        community_name.update!(value: "#{community_name.value} Community")
      end
    end
  end
end
