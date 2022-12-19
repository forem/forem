module DataUpdateScripts
  class BackfillNavigationLinksColumnDisplayTo
    def run
      NavigationLink.where(display_only_when_signed_in: true).update(display_to: "logged_in")
    end
  end
end
