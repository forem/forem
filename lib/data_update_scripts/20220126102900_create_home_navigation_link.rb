module DataUpdateScripts
  class CreateHomeNavigationLink
    def run
      NavigationLink.create_or_update_by_identity(
        name: "Home",
        url: URL.url("/"),
        icon: Rails.root.join("app/assets/images/twemoji/house.svg").read,
        display_only_when_signed_in: false,
        position: 1,
        section: :default,
      )

      # Increment all other default section links to account for new home link, and update to be 1-based
      NavigationLink.where(section: :default).find_each do |link|
        new_position = link.position + 2
        link.update_columns(position: new_position)
      end
    end
  end
end
