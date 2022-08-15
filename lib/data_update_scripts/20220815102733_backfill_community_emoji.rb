module DataUpdateScripts
  class BackfillCommunityEmoji
    def run
      return if Settings::Community.community_emoji.blank?

      new_community_name = "#{Settings::Community.community_name} #{Settings::Community.community_emoji}"
      Settings::Community.community_name = new_community_name
    end
  end
end
