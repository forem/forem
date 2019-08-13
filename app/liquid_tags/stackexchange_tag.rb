class StackexchangeTag < LiquidTagBase
  PARTIAL = "liquids/stackexchange".freeze
  # update API version here and in stackexchange_tag_spec when a new version is out
  API_URL = "https://api.stackexchange.com/2.2/".freeze
  # Filter codes come from the example tools in the docs. For example: https://api.stackexchange.com/docs/posts-by-ids
  FILTERS = {
    "post" => "!3tz1WbZW5JxrG-f99",
    "answer" => "!Fcb(61J.xH9ZW2D7KF1bbM_J7X",
    "question" => "!*1SgQGDOL9bPBHULz9sKS.y6qv7V9fYNszvdhDuv5",
    "site" => "!mWxO_PNa4i"
  }.freeze

  attr_reader :site, :post_type

  def initialize(tag_name, input, tokens)
    super
    @site = parse_site(input)
    @post_type = "question"
    @json_content = get_data(input)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        site: @site,
        pretty_site_name: pretty_site_name,
        title: @json_content["title"],
        created_at: @json_content["creation_date"],
        score: @json_content["score"],
        comment_count: @json_content["comment_count"],
        answer_count: @json_content["answer_count"],
        post_type: @post_type,
        post_url: @json_content["link"],
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

  def valid_input?(match_data)
    return false if match_data.nil?

    (match_data =~ /\A\d{1,10}\Z/i)&.zero?
  end

  def handle_response_error(response)
    raise StandardError, "Calling StackExchange API failed: #{response&.error_message}" if response.code != 200
    raise StandardError, "Couldn't find a post with that ID: {% #{tag_name} #{input} %}" if response["items"].length.zero?
  end

  def get_data(input)
    match_data = input.match(/\d+/i)
    raise StandardError, "Invalid Stack Exchange ID: {% #{tag_name} #{input} %}" unless valid_input?(match_data)

    id = match_data[0]

    post_response = HTTParty.get("#{API_URL}posts/#{id}?site=#{@site}&filter=#{FILTERS['post']}&key=#{ApplicationConfig['STACK_EXCHANGE_APP_KEY']}")

    handle_response_error(post_response)

    @post_type = post_response["items"][0]["post_type"]
    final_response = HTTParty.get("#{API_URL}#{@post_type.pluralize}/#{id}?site=#{@site}&filter=#{FILTERS[@post_type]}&key=#{ApplicationConfig['STACK_EXCHANGE_APP_KEY']}")

    handle_response_error(final_response)

    final_response["items"][0]
  end

  def pretty_site_name
    return "Stack Overflow" if @site == "stackoverflow"

    response = HTTParty.get("#{API_URL}info?site=#{@site}&filter=#{FILTERS['site']}&key=#{ApplicationConfig['STACK_EXCHANGE_APP_KEY']}")
    handle_response_error(response)

    response["items"][0]["site"]["name"]
  end
end

Liquid::Template.register_tag("stackoverflow", StackexchangeTag)
Liquid::Template.register_tag("stackexchange", StackexchangeTag)
