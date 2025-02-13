class BlueskyTag < LiquidTagBase
  PARTIAL = "liquids/bluesky".freeze

  # This regex matches a standard Bluesky web URL, e.g.:
  #   https://bsky.app/profile/did:plc:nmqm4vp5wieoeexrlvr345we/post/3ldhpt43zps2g
  REGISTRY_REGEXP = %r{\Ahttps?:\/\/bsky\.app\/profile\/(?<did>(?:did:plc:[a-z0-9]+|[^\/]+))\/post\/(?<post_id>[a-z0-9]+)\/?\z}i

  # Also allow an AT-URI format, e.g.:
  #   at://did:plc:nmqm4vp5wieoeexrlvr345we/app.bsky.feed.post/3ldhpt43zps2g
  VALID_ID_REGEXP = %r{\A(at://)?did:plc:[a-z0-9]+/app\.bsky\.feed\.post/[a-z0-9]+\Z}i

  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  # In case UnifiedEmbed tries to validate the URL by fetching metadata,
  # this override tells it to always consider Bluesky URLs valid.
  def self.valid_url?(_url)
    true
  end

  def initialize(_tag_name, input, _parse_context)
    super
    # Clean the input
    input = CGI.unescape_html(strip_tags(input))
    @parsed = parse_id_or_url(input)
  end

  def render(_context)
    # Now that we've parsed the input, you can use the values to
    # render your embed code, for example by calling the oEmbed endpoint.
    # Get json response from the oEmbed endpoint
    response = HTTParty.get("https://embed.bsky.app/oembed?url=#{@parsed[:url]}",
                            headers: {
                              "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})",
                              "Accept" => "application/json"
                            }
                            )

    @html = response["html"]

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        html: @html,
      }
    )
  end

  private

  def parse_id_or_url(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    unless match
      raise StandardError, "Invalid Bluesky URL"
    end

    if match.names.include?("did") && match.names.include?("post_id")
      did = match["did"]
      post_id = match["post_id"]
      {
        url: "https://bsky.app/profile/#{did}/post/#{post_id}",
        at_uri: "at://#{did}/app.bsky.feed.post/#{post_id}"
      }
    else
      # Fallback: try to match an AT-URI format
      at_match = input.match(%r{\Aat://(?<did>did:plc:[a-z0-9]+)/app\.bsky\.feed\.post/(?<post_id>[a-z0-9]+)\Z}i)
      if at_match
        did = at_match["did"]
        post_id = at_match["post_id"]
        {
          url: "https://bsky.app/profile/#{did}/post/#{post_id}",
          at_uri: input.start_with?("at://") ? input : "at://#{input}"
        }
      else
        raise StandardError, "Invalid Bluesky URL"
      end
    end
  end
end

Liquid::Template.register_tag("bluesky", BlueskyTag)
UnifiedEmbed.register(BlueskyTag, regexp: BlueskyTag::REGISTRY_REGEXP)
