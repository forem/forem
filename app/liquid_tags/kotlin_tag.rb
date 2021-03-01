class KotlinTag < LiquidTagBase
  PARTIAL = "liquids/kotlin".freeze
  PARAM_REGEXP = /\A[a-zA-Z0-9]+\z/.freeze

  def initialize(_tag_name, link, _parse_context)
    super
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split.first
    @embedded_url = KotlinTag.embedded_url(the_link)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url: @embedded_url
      },
    )
  end

  def self.embedded_url(link)
    "https://play.kotlinlang.org/embed?#{URI.encode_www_form(parse_link(link))}"
  end

  def self.parse_link(link)
    begin
      url = URI(link)
    rescue StandardError
      raise_error
    end
    hostname_ok = url.hostname == "pl.kotl.in"
    short = url.path.delete("/")
    raise_error unless hostname_ok && valid_param?(short)
    parse_params(url, short)
  end

  def self.parse_params(url, short)
    query = url.query.nil? ? [] : URI.decode_www_form(url.query)
    result = { short: short }
    %i[from to theme readOnly].each do |param|
      value = query.assoc(param.id2name)&.last
      result[param] = valid_param?(value) ? value : ""
    end
    result
  end

  def self.valid_param?(value)
    !value&.match(PARAM_REGEXP)&.nil?
  end

  def raise_error
    raise StandardError, "Invalid Kotlin Playground URL"
  end
end

Liquid::Template.register_tag("kotlin", KotlinTag)
