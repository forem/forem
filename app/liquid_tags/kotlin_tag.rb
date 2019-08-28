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
    raise_error unless hostname_ok && is_valid_param(short)
    self.parse_params(url, short)
  end

  def self.parse_params(url, short)
    query = url.query.nil? ?  [] : URI.decode_www_form(url.query)
    result = {:short => short}
    [:from, :to, :theme, :readOnly].each { |param|
      value = query.assoc(param.id2name)&.last
      result[param] = is_valid_param(value) ? value : ""
    }
    result
  end

  def self.is_valid_param(value)
    return false if value.nil?
    value.match(/^[a-zA-Z0-9]+$/) != nil
  end

  def self.raise_error
    raise StandardError, "Invalid Kotlin Playground URL"
  end
end

Liquid::Template.register_tag("kotlin", KotlinTag)
