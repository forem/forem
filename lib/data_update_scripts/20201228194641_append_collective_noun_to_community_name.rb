module DataUpdateScripts
  class AppendCollectiveNounToCommunityName
    def run
      return if Settings::General.collective_noun_disabled || Settings::General.collective_noun.blank?

      Settings::General.community_name = "#{Settings::General.community_name} #{Settings::General.collective_noun}"
    end
  end
end
