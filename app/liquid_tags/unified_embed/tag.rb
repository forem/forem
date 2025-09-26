require "net/http"

module UnifiedEmbed
  class Tag < LiquidTagBase
    MAX_REDIRECTION_COUNT = 3
    MINIMAL_ALLOWLIST = [LinkTag].freeze

    def self.new(tag_name, input, parse_context)
      stripped_input = ActionController::Base.helpers.strip_tags(input).strip

      # Parse input to check for 'minimal' keyword
      parts = stripped_input.split(/\s+/)
      minimal_mode = parts.include?("minimal")

      # Find the URL (first part that looks like a URL)
      url = parts.find { |part| part.match?(%r{^https?://}) } || parts.first

      handler_before_validation = UnifiedEmbed::Registry.find_handler_for(link: url)

      validated_link = if handler_before_validation&.dig(:skip_validation)
                         url
                       else
                         validate_link(input: url)
                       end

      # In minimal mode, only use allow-listed embeds, otherwise fall back to OpenGraphTag
      klass = if minimal_mode
                if handler_before_validation && MINIMAL_ALLOWLIST.include?(handler_before_validation[:klass])
                  handler_before_validation[:klass]
                else
                  OpenGraphTag
                end
              else
                UnifiedEmbed::Registry.find_liquid_tag_for(link: validated_link)
              end

      klass.__send__(:new, tag_name, validated_link, parse_context)
    end

    def self.validate_link(input:, retries: MAX_REDIRECTION_COUNT, method: Net::HTTP::Head)
      uri = URI.parse(input.split.first)
      return input if uri.host == "twitter.com" || uri.host == "x.com" || uri.host == "bsky.app"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if http.port == 443

      path = uri.path.empty? ? "/" : uri.path
      req = method.new(path + (uri.query ? "?#{uri.query}" : ""))
      req["User-Agent"] = "#{safe_user_agent} (#{URL.url})"

      response = http.request(req)

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
