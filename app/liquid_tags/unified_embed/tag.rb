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
    # @param input [String] the URL and additional options for that
    #        particular embed.
    # @param parse_context [Liquid::ParseContext]
    #
    # @return [LiquidTagBase]
    def self.new(tag_name, input, parse_context)
      stripped_input = ActionController::Base.helpers.strip_tags(input).strip

      # Extract just the URL from the input, without any params, for validation
      actual_link = extract_only_url(stripped_input)

      # When Listings are disabled, it makes little sense to perform a validate_link
      # network call.
      handle_listings_disabled!(actual_link)

      # Before matching against the embed registry, we check if the link
      # is valid (e.g. no typos).
      # If the link is invalid, we raise an error encouraging the user to
      # check their link and try again.
      validate_link!(actual_link)
      klass = UnifiedEmbed::Registry.find_liquid_tag_for(link: stripped_input)

      # If there are no OG metatags, we shall render an A-tag. Since the link
      # has been validated, at least this A-tag will not 404.
      #
      # Why the __send__?  Because a LiquidTagBase class "privatizes"
      # the `.new` method.  And we want to instantiate the specific
      # liquid tag for the given link.
      klass.__send__(:new, tag_name, stripped_input, parse_context)
    end

    def self.validate_link!(link)
      uri = URI.parse(link)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if http.port == 443

      req = Net::HTTP::Head.new(uri.request_uri)
      req["User-Agent"] = "#{Settings::Community.community_name} (#{URL.url})"
      response = http.request(req)

      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        warn "redirected to #{response['location']}"
      when Net::HTTPNotFound
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.not_found")
      else
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
      end
    rescue SocketError
      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
    end

    def self.handle_listings_disabled!(link)
      return unless link.start_with?("#{URL.url}/listings/") && !Listing.feature_enabled?

      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.listings_disabled")
    end

    def self.extract_only_url(input)
      url_portion = input.split.length > 1 ? input.split[0] : input

      # remove any params
      url_portion.split("?")[0]
    end
  end
end

Liquid::Template.register_tag("embed", UnifiedEmbed::Tag)
