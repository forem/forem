class UserSubscriptionTag < LiquidTagBase
  def initialize(_tag_name, cta_text, _tokens)
    @cta_text = cta_text.strip
  end

  def render(context); end
end

Liquid::Template.register_tag("user_subscription", UserSubscriptionTag)
