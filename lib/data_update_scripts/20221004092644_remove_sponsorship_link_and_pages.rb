module DataUpdateScripts
  class RemoveSponsorshipLinkAndPages
    def run
      # to account for sponsor, sponsors, sponsorship, sponsorships
      Page.where("slug LIKE ?", "%sponsor%")&.destroy_all
      NavigationLink.where("url LIKE ?", "%sponsor%")&.destroy_all
    end
  end
end
