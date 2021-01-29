module DataUpdateScripts
  class MakeLocalNavigationLinksRelative
    def run
      NavigationLink.find_each do |navigation_link|
        parsed_url = URI.parse(navigation_link.url)
        next if parsed_url.relative?

        navigation_link.save
      end
    end
  end
end
