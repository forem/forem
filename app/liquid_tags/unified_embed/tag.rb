require "net/http"

module UnifiedEmbed
  # This liquid tag is present to facilitate a unified user experience
  # for declaring that they want a URL to have "embedded" behavior.
  #
  # What do we mean by embedded behavior?  A more contextually rich
  # rendering of the URL, instead of a simple "A-tag".
  #
  # @see https://github.com/forem/forem/issues/15099 for details on the
  #      purpose of this class.
  class Tag < LiquidTagBase
    # You will not get a UnifiedEmbedTag instance, as we are instead
    # using this class as a lookup (e.g., Factory pattern?) for the
    # LiquidTagBase instance that is applicable for the given :link.
    #
    # @param tag_name [String] in the UI, this was liquid tag name
    #        (e.g., `{% tag_name link %}`)
    # @param link [String] the URL and additional options for that
    #        particular service.
    # @param parse_context [Liquid::ParseContext]
    #
    # @return [LiquidTagBase]
    def self.new(tag_name, link, parse_context)
      stripped_link = ActionController::Base.helpers.strip_tags(link).strip

      # Before matching against the embed registry, we check if the link
      # is valid (e.g. no typos).
      # If the link is invalid, we raise an error encouraging the user to
      # check their link and try again.
      validated_link = validate_link(stripped_link)
      klass = UnifiedEmbed::Registry.find_liquid_tag_for(link: validated_link)

      # If the link is valid but doesn't match the registry, we return
      # an "unsupported URL" error. Eventually we shall render a fallback
      # embed using OpenGraph/TwitterCard metadata (if available).
      # If there are no OG metatags, then we render an A-tag. Since the link
      # has been validated, at least this A-tag will not 404.
      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.unsupported_url") unless klass

      # Why the __send__?  Because a LiquidTagBase class "privatizes"
      # the `.new` method.  And we want to instantiate the specific
      # liquid tag for the given link.
      klass.__send__(:new, tag_name, validated_link, parse_context)
    end

    def self.validate_link(link)
      uri = URI.parse(link)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if http.port == 443
      path = uri.path.presence || "/"
      response = http.request_head(path)

      unless response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPMovedPermanently)
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.not_found")
      end

      link
    rescue SocketError
      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
    end
  end
end

Liquid::Template.register_tag("embed", UnifiedEmbed::Tag)
