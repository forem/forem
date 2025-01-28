module UnifiedEmbed
  # The purpose of this singleton class is to provide a registry for the
  # numerous "link/embedded" type liquid tags.
  #
  # Each of those liquid tags must self-register their lookup regular
  # expression.
  class Registry
    include Singleton

    def self.current
      instance
    end

    # @api public
    #
    # @param klass [Class] the LiquidTag class that we use when we match
    #        the given :regexp
    # @param regexp [Regexp] the regular expression that when matched
    #        means we use the associated :klass
    def self.register(klass, regexp:)
      instance.register(klass, regexp: regexp)
    end

    # @api public
    #
    # @param link [String] the string that includes the URI for the
    #        embed and possibly additional attributes, depending on how
    #        the registered liquid tag parses this string.
    # @return [Class] a descendant class of LiquidTagBase
    def self.find_liquid_tag_for(link:)
      instance.find_liquid_tag_for(link: link)
    end

    def initialize
      @registry = []
    end

    def register(klass, regexp:)
      @registry << [regexp, klass]
    end

    def find_liquid_tag_for(link:)
      possible_domains = Subforem.cached_domains + [Settings::General.app_domain]
      link_path = Addressable::URI.parse(link).path
      return LinkTag if link.match?(%r{https?://(#{possible_domains.map { |domain| Regexp.escape(domain) }.join("|")})/(?<username>[^/]+)/(?<slug>[^/]+)}) && Article.find_by(path: link_path)
      _regexp, klass = @registry.detect { |regexp, _tag_class| regexp.match?(link) }
      klass.presence || OpenGraphTag
    end
  end
end
