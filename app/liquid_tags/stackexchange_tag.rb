class StackexchangeTag < LiquidTagBase
  PARTIAL = "liquids/stackexchange".freeze
  # update API version here and in stackexchange_tag_spec when a new version is out
  API_URL = "https://api.stackexchange.com/2.2/".freeze
  # Filter codes come from the example tools in the docs. For example: https://api.stackexchange.com/docs/posts-by-ids
  FILTERS = {
    "post" => "!3tz1WbZW5JxrG-f99",
    "answer" => "!.Fjr38AQkcvWfJTF-2exSL50At_pT",
    "question" => "!*1SgQGDOL9bPBHULz9sKS.y6qv7V9fYNszvdhDuv5",
    "site" => "!mWxO_PNa4i"
  }.freeze
  ID_REGEXP = /\A\d{1,20}\z/

  attr_reader :site, :post_type

  def initialize(_tag_name, input, _parse_context)
    super

    @site = parse_site(input.strip)
    @post_type = "question"
    @json_content = get_data(input.strip)
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

  def valid_site?(site)
    (site =~ /[a-z.]+/i)&.zero?
  end

  def parse_site(input)
    return "stackoverflow" if tag_name == "stackoverflow"

    site = input.match(/[a-z.]+/i)[0]
    raise StandardError, "Invalid Stack Exchange site: {% #{tag_name} #{input} %}" unless valid_site?(site)

    site
  end

  def valid_input?(input)
    return false if input.nil?

    ID_REGEXP.match?(input.split.first)
  end

  def handle_response_error(response, input)
    raise StandardError, "Calling StackExchange API failed: #{response&.error_message}" if response.code != 200

    return unless response["items"].length.zero?

    raise StandardError, "Couldn't find a post with that ID: {% #{tag_name} #{input} %}"
  end

  def get_data(input)
    raise StandardError, "Invalid Stack Exchange ID: {% #{tag_name} #{input} %}" unless valid_input?(input)

    id = input.split.first

    url = "#{API_URL}posts/#{id}?site=#{@site}&filter=#{FILTERS['post']}" \
          "&key=#{ApplicationConfig['STACK_EXCHANGE_APP_KEY']}"
    post_response = HTTParty.get(url)

    handle_response_error(post_response, input)

    @post_type = post_response["items"][0]["post_type"]

    url = "#{API_URL}#{@post_type.pluralize}/#{id}?site=#{@site}" \
          "&filter=#{FILTERS[@post_type]}&key=#{ApplicationConfig['STACK_EXCHANGE_APP_KEY']}"
    final_response = HTTParty.get(url)

    handle_response_error(final_response, input)

    final_response["items"][0]
  end
end

Liquid::Template.register_tag("stackoverflow", StackexchangeTag)
Liquid::Template.register_tag("stackexchange", StackexchangeTag)
