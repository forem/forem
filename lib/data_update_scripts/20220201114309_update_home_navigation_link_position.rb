module DataUpdateScripts
  class UpdateHomeNavigationLinkPosition
    def run
      NavigationLink.create_or_update_by_identity(
        name: "Home",
        url: URL.url("/"),
        icon: Rails.root.join("app/assets/images/twemoji/house.svg").read,
        display_only_when_signed_in: false,
        position: 1,
        section: :default,
      )
    end
  end
end
