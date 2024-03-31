class StackexchangeTag < LiquidTagBase
  PARTIAL = "liquids/stackexchange".freeze
  REGISTRY_REGEXP = %r{https://(?:(?<subdomain>\w+)\.)?(?:stackexchange\.com|stackoverflow\.com)/(?<post_type>q|a|questions)/(?<id>\d{1,20})}
  ID_REGEXP = /\A(?<id>\d{1,20})\Z/
  SITE_REGEXP = /(?<subdomain>\b[a-zA-Z]+\b)/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, ID_REGEXP, SITE_REGEXP].freeze
  STACKOVERFLOW_REGEXP = %r{https://stackoverflow\.com/(q|a|questions)/\d{1,20}(?:/[\w-]+)?}
  API_URL = "https://api.stackexchange.com/2.3/".freeze
  # Filter codes come from the example tools in the docs. For example: https://api.stackexchange.com/docs/posts-by-ids
  FILTERS = {
    "post" => "!3tz1WbZW5JxrG-f99",
    "answer" => "!.Fjr38AQkcvWfJTF-2exSL50At_pT",
    "question" => "!*1SgQGDOL9bPBHULz9sKS.y6qv7V9fYNszvdhDuv5",
    "site" => "!mWxO_PNa4i"
  }.freeze

  attr_reader :site, :post_type

  def initialize(_tag_name, input, _parse_context)
    super

    stripped_input  = strip_tags(input)
    unescaped_input = CGI.unescape_html(stripped_input)
    @site = parse_site(unescaped_input)
    @json_content, @post_type = get_data(unescaped_input)
  end

  def render(_context)
    default_link = "https://stackoverflow.com/a/#{@json_content['answer_id'] || @json_content['question_id']}"

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        site: @site,
        title: @json_content["title"],
        created_at: @json_content["creation_date"],
        score: @json_content["score"],
        comment_count: @json_content["comment_count"],
        answer_count: @json_content["answer_count"],
        post_type: @post_type,
        post_url: @json_content["link"] || default_link,
        body: @json_content["body"]
      },
    )
  end

  private

  def parse_site(input)
    return "stackoverflow" if tag_name == "stackoverflow" || input.match?(STACKOVERFLOW_REGEXP)

    match = pattern_match_for(input, REGEXP_OPTIONS)
    # rubocop:disable Layout/LineLength
    raise StandardError, I18n.t("liquid_tags.stackexchange_tag.invalid_site", tag: tag_name, input: input) unless match && match_group_present?(match, "subdomain")
    # rubocop:enable Layout/LineLength

    match[:subdomain].downcase
  end

  def match_group_present?(match, group_name)
    match.names.include?(group_name)
  end

  def get_data(input)
    id = input.split.first
    match = pattern_match_for(id, REGEXP_OPTIONS)
    unless match && match_group_present?(match, "id")
      raise StandardError, I18n.t("liquid_tags.stackexchange_tag.invalid_id", tag: tag_name, input: input)
    end

    url = "#{API_URL}posts/#{match[:id]}?site=#{@site}&filter=#{FILTERS['post']}" \
          "&key=#{ApplicationConfig['STACK_EXCHANGE_APP_KEY']}"
    post_response = HTTParty.get(url)

    handle_response_error(post_response, input)

    @post_type = post_response["items"][0]["post_type"]

    url = "#{API_URL}#{@post_type.pluralize}/#{match[:id]}?site=#{@site}" \
          "&filter=#{FILTERS[@post_type]}&key=#{ApplicationConfig['STACK_EXCHANGE_APP_KEY']}"
    final_response = HTTParty.get(url)

    handle_response_error(final_response, input)

    [final_response["items"][0], @post_type]
  end

  def handle_response_error(response, input)
    raise StandardError, "Calling StackExchange API failed: #{response&.error_message}" unless response.ok?

    return unless response["items"].empty?

    raise StandardError, I18n.t("liquid_tags.stackexchange_tag.post_not_found", tag: tag_name, input: input)
  end
end

Liquid::Template.register_tag("stackoverflow", StackexchangeTag)
Liquid::Template.register_tag("stackexchange", StackexchangeTag)
UnifiedEmbed.register(StackexchangeTag, regexp: StackexchangeTag::REGISTRY_REGEXP)
