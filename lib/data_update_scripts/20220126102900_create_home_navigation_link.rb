module DataUpdateScripts
  class CreateHomeNavigationLink
    def run
      NavigationLink.where(url: "/").first_or_create(
        name: "Home",
        url: URL.url("/"),
        icon: File.read(Rails.root.join("app/assets/images/twemoji/house.svg")),
        display_only_when_signed_in: false,
        position: -1,
        section: :default,
      )
    end
  end
end
