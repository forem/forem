module DataUpdateScripts
  class BackfillSectionColumnForNavigationLinks
    OTHER_LINKS = [
      "/code-of-conduct",
      "/privacy",
      "/terms",
    ].freeze

    def run
      NavigationLink.where(url: OTHER_LINKS).find_each do |link|
        link.update_column(section: 1)
      end
    end
  end
end
