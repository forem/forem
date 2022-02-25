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
      klass = UnifiedEmbed::Registry.find_liquid_tag_for(link: stripped_link)
      # If the link does not match the embed registry, we check if the link
      # is valid (e.g. no typos).
      # If the link is invalid, we raise an error encouraging the user to
      # check their link and try again.
      # If the link is valid, we fallback to using OpenGraph/TwitterCard
      # metadata (if available) to render an embed.
      # If there are no OG metatags, then we render an A-tag. Since the link
      # has been validated, at least this A-tag will not 404.

      # raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url") unless klass

      validate_link(stripped_link) unless klass

      # Why the __send__?  Because a LiquidTagBase class "privatizes"
      # the `.new` method.  And we want to instantiate the specific
      # liquid tag for the given link.
      klass.__send__(:new, tag_name, stripped_link, parse_context)
    end

    def self.validate_link(link)
      uri = URI.parse(link)
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.get(uri.request_uri)

      # eventually, this error will be replaced with the fallback OpenGrapg embed
      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.unsupported_url") if response.is_a?(Net::HTTPSuccess)

      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
    end
  end
end

Liquid::Template.register_tag("embed", UnifiedEmbed::Tag)
