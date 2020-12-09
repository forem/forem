module DataUpdateScripts
  class RemoveCollectiveNounFromConfig
    def run
      SiteConfig.find_by(var: "collective_noun")&.or(SiteConfig.find_by(var: "collective_noun_disabled"))&.destroy
    end
  end
end
