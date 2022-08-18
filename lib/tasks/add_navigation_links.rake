# rubocop:disable Metrics/BlockLength
namespace :navigation_links do
  def image_path(*paths)
    File.read(Rails.root.join("app/assets/images/#{paths.join('/')}")).freeze
  end

  def twemoji_path(name)
    image_path("twemoji", name)
  end

  home_icon = twemoji_path("house.svg")
  reading_icon = twemoji_path("drawer.svg")
  contact_icon = twemoji_path("contact.svg")
  thumb_up_icon = twemoji_path("thumb-up.svg")
  smart_icon = twemoji_path("smart.svg")
  look_icon = twemoji_path("look.svg")
  listing_icon = twemoji_path("listing.svg")
  mic_icon = twemoji_path("mic.svg")
  camera_icon = twemoji_path("camera.svg")
  tag_icon = twemoji_path("tag.svg")
  bulb_icon = twemoji_path("bulb.svg")
  shopping_icon = twemoji_path("shopping.svg")
  heart_icon = twemoji_path("heart.svg")
  rainbowdev = image_path("rainbowdev.svg")

  def perform_create_of_navigation_links?
    # Someone really wants this
    return true if ApplicationConfig["CREATE_NAVIGATION_LINKS"]

    # This logic echoes the InternalPolicy behavior which is used in the
    # Admin::AppliciationController.
    return false if User.with_any_role(*Authorizer::RoleBasedQueries::ANY_ADMIN_ROLES).any?

    true
  end

  desc "Create navigation links for new forem"
  task create: :environment do
    if perform_create_of_navigation_links?
      puts "Creating navigation links"
      # [@jeremyf] I went ahead and atomized these tasks so we _could_ call them individually if
      #            desired.  I did not add descriptions so those tasks will not show up in the task
      #            list.
      Rake::Task["navigation_links:find_or_create:home"].invoke
      Rake::Task["navigation_links:find_or_create:readinglist"].invoke
      Rake::Task["navigation_links:find_or_create:contact"].invoke
      Rake::Task["navigation_links:find_or_create:code_of_conduct"].invoke
      Rake::Task["navigation_links:find_or_create:privacy"].invoke
      Rake::Task["navigation_links:find_or_create:terms"].invoke
    else
      # Adding just a bit of logging
      Rails.logger.info "Skipping creation of navigation links"
    end
  end

  namespace :find_or_create do
    task home: :environment do
      NavigationLink.create_or_update_by_identity(
        name: "Home",
        url: URL.url("/"),
        icon: home_icon,
        display_to: :all,
        position: 1,
        section: :default,
      )
    end

    task readinglist: :environment do
      NavigationLink.create_or_update_by_identity(
        url: URL.url("readinglist"),
        name: "Reading List",
        icon: reading_icon,
        display_to: :logged_in,
        position: 2,
        section: :default,
      )
    end

    task contact: :environment do
      NavigationLink.create_or_update_by_identity(
        name: "Contact",
        url: URL.url("contact"),
        icon: contact_icon,
        display_to: :all,
        position: 3,
        section: :default,
      )
    end

    task code_of_conduct: :environment do
      NavigationLink.create_or_update_by_identity(
        name: "Code of Conduct",
        url: URL.url(Page::CODE_OF_CONDUCT_SLUG),
        icon: thumb_up_icon,
        display_to: :all,
        position: 1,
        section: :other,
      )
    end

    task privacy: :environment do
      NavigationLink.create_or_update_by_identity(
        name: "Privacy Policy",
        url: URL.url(Page::PRIVACY_SLUG),
        icon: smart_icon,
        display_to: :all,
        position: 2,
        section: :other,
      )
    end

    task terms: :environment do
      NavigationLink.create_or_update_by_identity(
        name: "Terms of Use",
        url: URL.url(Page::TERMS_SLUG),
        icon: look_icon,
        display_to: :all,
        position: 3,
        section: :other,
      )
    end
  end

  desc "Update DEV's navigation_links"
  task update: :environment do
    protocol = ApplicationConfig["APP_PROTOCOL"].freeze
    domain = Rails.application&.initialized? ? Settings::General.app_domain : ApplicationConfig["APP_DOMAIN"]
    base_url = "#{protocol}#{domain}".freeze

    NavigationLink.create_or_update_by_identity(
      url: "/",
      name: "Home",
      icon: home_icon,
      display_to: :all,
      position: 1,
      section: :default,
    )

    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/readinglist",
      name: "Reading List",
      icon: reading_icon,
      display_to: :logged_in,
      position: 2,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/listings",
      name: "Listings",
      icon: listing_icon,
      display_to: :all,
      position: 3,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/pod",
      name: "Podcasts",
      icon: mic_icon,
      display_to: :all,
      position: 4,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/videos",
      name: "Videos",
      icon: camera_icon,
      display_to: :all,
      position: 5,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/tags",
      name: "Tags",
      icon: tag_icon,
      display_to: :all,
      position: 6,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/faq",
      name: "FAQ",
      icon: bulb_icon,
      display_to: :all,
      position: 7,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "https://shop.dev.to/",
      name: "DEV Shop",
      icon: shopping_icon,
      display_to: :all,
      position: 6,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/sponsors",
      name: "Sponsors",
      icon: heart_icon,
      display_to: :all,
      position: 7,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/about",
      name: "About",
      icon: rainbowdev,
      display_to: :all,
      position: 8,
      section: :default,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/contact",
      name: "Contact",
      icon: contact_icon,
      display_to: :all,
      position: 9,
      section: :default,
    )

    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/code-of-conduct",
      name: "Code of Conduct",
      icon: thumb_up_icon,
      display_to: :all,
      position: 1,
      section: :other,
    )

    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/privacy",
      name: "Privacy Policy",
      icon: smart_icon,
      display_to: :all,
      position: 2,
      section: :other,
    )
    NavigationLink.create_or_update_by_identity(
      url: "#{base_url}/terms",
      name: "Terms of Use",
      icon: look_icon,
      display_to: :all,
      position: 3,
      section: :other,
    )
  end
end
# rubocop:enable Metrics/BlockLength
