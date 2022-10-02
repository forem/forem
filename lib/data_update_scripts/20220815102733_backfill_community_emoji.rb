module DataUpdateScripts
  class BackfillCommunityEmoji
    # We can remove this file in the future once we've given self hosters sufficient
    # time to update their Forems to run this script.
    def run
      return if Settings::Community.community_emoji.blank?
      return if Settings::Community.community_name.include?(Settings::Community.community_emoji)

      new_community_name = "#{Settings::Community.community_name} #{Settings::Community.community_emoji}"
      Settings::Community.community_name = new_community_name
    end
  end
end
