module DataUpdateScripts
  class AddNavigationLinks
    PROTOCOL = ApplicationConfig["APP_PROTOCOL"].freeze
    DOMAIN = Rails.application&.initialized? ? Settings::General.app_domain : ApplicationConfig["APP_DOMAIN"]
    BASE_URL = "#{PROTOCOL}#{DOMAIN}".freeze

    READING_ICON = File.read(Rails.root.join("app/assets/images/twemoji/drawer.svg")).freeze
    THUMB_UP_ICON = File.read(Rails.root.join("app/assets/images/twemoji/thumb-up.svg")).freeze
    SMART_ICON = File.read(Rails.root.join("app/assets/images/twemoji/smart.svg")).freeze
    LOOK_ICON = File.read(Rails.root.join("app/assets/images/twemoji/look.svg")).freeze
    CONTACT_ICON = File.read(Rails.root.join("app/assets/images/twemoji/contact.svg")).freeze

    def run
      NavigationLink.where(name: "Reading List", url: "#{BASE_URL}/readinglist", icon: READING_ICON,
                           display_only_when_signed_in: true, position: 0).first_or_create
      NavigationLink.where(name: "Code of Conduct", url: "#{BASE_URL}/code-of-conduct", icon: THUMB_UP_ICON,
                           display_only_when_signed_in: false, position: 1).first_or_create
      NavigationLink.where(name: "Privacy Policy", url: "#{BASE_URL}/privacy", icon: SMART_ICON,
                           display_only_when_signed_in: false, position: 2).first_or_create
      NavigationLink.where(name: "Terms of Use", url: "#{BASE_URL}/terms", icon: LOOK_ICON,
                           display_only_when_signed_in: false, position: 3).first_or_create
      NavigationLink.where(name: "Contact", url: "#{BASE_URL}/contact", icon: CONTACT_ICON,
                           display_only_when_signed_in: false, position: 4).first_or_create
    end
  end
end
