class KotlinTag < LiquidTagBase
  PARTIAL = "liquids/kotlin".freeze

  def initialize(tag_name, link, tokens)
    super
    stripped_link = ActionController::Base.helpers.strip_tags(link)
    the_link = stripped_link.split(" ").first
    @locals = KotlinTag.parse_link(the_link)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: @locals,
    )
  end

  def self.parse_link(link)
    begin
      url = URI(link)
    rescue
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
    !value&.match(/^[a-zA-Z0-9]+$/)&.nil?
  end

  def raise_error
    raise StandardError, "Invalid Kotlin Playground URL"
  end
end

Liquid::Template.register_tag("kotlin", KotlinTag)
