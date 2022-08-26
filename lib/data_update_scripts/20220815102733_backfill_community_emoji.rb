module DataUpdateScripts
  class BackfillCommunityEmoji
    def run
      return if Settings::Community.community_emoji.blank?
      return if Settings::Community.community_name.include?(Settings::Community.community_emoji)

      new_community_name = "#{Settings::Community.community_name} #{Settings::Community.community_emoji}"
      Settings::Community.community_name = new_community_name
    end
  end
end
