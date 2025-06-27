require "net/http"

module UnifiedEmbed
  class Tag < LiquidTagBase
    MAX_REDIRECTION_COUNT = 3

    def self.new(tag_name, input, parse_context)
      stripped_input = ActionController::Base.helpers.strip_tags(input).strip

      handler_before_validation = UnifiedEmbed::Registry.find_handler_for(link: stripped_input)

      validated_link = if handler_before_validation&.dig(:skip_validation)
                         stripped_input
                       else
                         validate_link(input: stripped_input)
                       end

      klass = UnifiedEmbed::Registry.find_liquid_tag_for(link: validated_link)

      klass.__send__(:new, tag_name, validated_link, parse_context)
    end

    def self.validate_link(input:, retries: MAX_REDIRECTION_COUNT, method: Net::HTTP::Head)
      uri = URI.parse(input.split.first)
      return input if uri.host == "twitter.com" || uri.host == "x.com" || uri.host == "bsky.app"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if http.port == 443

      req = method.new(uri.request_uri)
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