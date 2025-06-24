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
    MAX_REDIRECTION_COUNT = 3
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

      # Before matching against the embed registry, we check if the link
      # is valid (e.g. no typos).
      # If the link is invalid, we raise an error encouraging the user to
      # check their link and try again.
      validated_link = validate_link(input: stripped_input)
      klass = UnifiedEmbed::Registry.find_liquid_tag_for(link: validated_link)

      # Why the __send__?  Because a LiquidTagBase class "privatizes"
      # the `.new` method.  And we want to instantiate the specific
      # liquid tag for the given link.
      klass.__send__(:new, tag_name, validated_link, parse_context)
    end

    def self.validate_link(input:, retries: MAX_REDIRECTION_COUNT, method: Net::HTTP::Head)
      uri = URI.parse(input.split.first)
      return input if uri.host == "twitter.com" || uri.host == "x.com" || uri.host == "bsky.app" # Twitter sends a forbidden like to codepen below

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if http.port == 443

      req = method.new(uri.request_uri)
      req["User-Agent"] = "#{safe_user_agent} (#{URL.url})"

      response = http.request(req)

      # This might be a temporary hack we can remove in the future. For some
      # reason, CodePen sometimes sends a 403 on initial request, it's likely a
      # misconfigured CloudFlare on their end, but making the request a second
      # time seems to fix it.
      if uri.host == "codepen.io" && response.is_a?(Net::HTTPForbidden)
        response = http.request(req)
      end

      case response
      when Net::HTTPSuccess
        input
      when Net::HTTPRedirection
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.too_many_redirects") if retries.zero?

        validate_link(input: response["location"], retries: retries - 1)
      when Net::HTTPMethodNotAllowed
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url") if retries.zero?

        validate_link(input: input, retries: retries, method: Net::HTTP::Get)
      when Net::HTTPNotFound
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.not_found")
      else
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
      end
    rescue SocketError
      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
    end

    def self.safe_user_agent(agent = Settings::Community.community_name)
      agent.gsub(/[^-_.()a-zA-Z0-9 ]+/, "-")
    end
  end
end

Liquid::Template.register_tag("embed", UnifiedEmbed::Tag)
