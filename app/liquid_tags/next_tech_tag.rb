class NextTechTag < LiquidTagBase
  PARTIAL = "liquids/nexttech".freeze

  def initialize(tag_name, share_url, tokens)
    super
    @token = parse_share_url(share_url)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        token: @token
      },
    )
  end

  private

  # Returns the share token from the end of the share URL.
  def parse_share_url(share_url)
    clean_share_url = ActionController::Base.helpers.strip_tags(share_url).delete(" ").gsub(/\?.*/, "")
    raise StandardError, "Invalid Next Tech share URL" unless valid_share_url?(clean_share_url)

    clean_share_url.split("/").last
  end

  # Examples of valid share URLs:
  #   - https://nt.dev/s/123456abcdef
  #   - http://nt.dev/s/123456abcdef/
  #   - nt.dev/s/123456abcdef
  def valid_share_url?(share_url)
    (share_url =~ /^(?:(?:http|https):\/\/)?nt\.dev\/s\/[a-z0-9]{12}\/{0,1}$/)&.zero?
  end
end

Liquid::Template.register_tag("nexttech", NextTechTag)
