module DataUpdateScripts
  class BackfillSectionColumnForNavigationLinks
    OTHER_LINKS = [
      "/code-of-conduct",
      "/privacy",
      "/terms",
    ].freeze

    def run
      NavigationLink.where(url: OTHER_LINKS).update(section: "other")
    end
  end
end
