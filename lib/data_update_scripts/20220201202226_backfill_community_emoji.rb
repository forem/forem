module DataUpdateScripts
  class BackfillCommunityEmoji
    def run
      return if Settings::Community.community_emoji.blank?

      Settings::Community.community_name.where_not(community_emoji: nil).find_each do |name|
        name.update!(community_name: name.community_emoji)
      end
    end
  end
end
