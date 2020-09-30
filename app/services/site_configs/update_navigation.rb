module SiteConfigs
  class UpdateNavigation
    class NavigationLink
      include ActiveModel::Validations

      URI_REGEXP = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze
      SVG_REGEXP = /\A<svg .*>/i.freeze

      validates :name, :url, :icon, presence: true
      validates :url, format: URI_REGEXP
      validates :icon, format: SVG_REGEXP

      def self.from_hash(hash)
        new(hash[:name], hash[:url], hash[:icon])
      end

      attr_reader :name, :url, :icon

      def initialize(name, url, icon)
        @name = name
        @url = url
        @icon = icon
      end
    end

    def self.call(navigation_links)
      new(navigation_links).call
    end

    attr_reader :errors

    def initialize(navigation_links)
      @navigation_links = navigation_links
      @errors = {}
    end

    def call
      @navigation_links.each_with_index do |attributes, index|
        navigation_link = NavigationLink.from_hash(attributes)
        next if navigation_link.valid?

        @errors[index] = navigation_link.errors.to_a
      end

      updated_navigation_list = SiteConfig.navigation + @navigation_links
      SiteConfig.navigation = updated_navigation_list if success?
      self
    end

    def success?
      @errors.empty?
    end
  end
end
