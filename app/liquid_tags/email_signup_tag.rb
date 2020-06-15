class EmailSignupTag < LiquidTagBase
  def initialize(_tag_name, _tokens); end

  def render(_context); end
end

Liquid::Template.register_tag("email_signup", EmailSignupTag)
