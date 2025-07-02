module UnifiedEmbed
  class Registry
    include Singleton

    def self.current
      instance
    end

    def self.register(klass, regexp:, skip_validation: false)
      instance.register(klass, regexp: regexp, skip_validation: skip_validation)
    end

    def self.find_handler_for(link:)
      instance.find_handler_for(link: link)
    end

    def self.find_liquid_tag_for(link:)
      instance.find_liquid_tag_for(link: link)
    end

    def initialize
      @registry = []
    end

    def register(klass, regexp:, skip_validation: false)
      @registry << { regexp: regexp, klass: klass, skip_validation: skip_validation }
    end

    def find_handler_for(link:)
      possible_domains = Subforem.cached_domains + [Settings::General.app_domain]
      link_path = Addressable::URI.parse(link).path
      if link.match?(%r{https?://(#{possible_domains.map { |domain| Regexp.escape(domain) }.join("|")})/(?<username>[^/]+)/(?<slug>[^/]+)}) && Article.find_by(path: link_path)
        return { klass: LinkTag, skip_validation: false }
      end

      @registry.detect { |handler| handler[:regexp].match?(link) }
    end

    def find_liquid_tag_for(link:)
      handler = find_handler_for(link: link)
      (handler&.dig(:klass)) || OpenGraphTag
    end
  end
end