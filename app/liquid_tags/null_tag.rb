class NullTag < Liquid::Block
  def initialize(tag_name, _markup, _options) # rubocop:disable Lint/MissingSuper
    raise StandardError, I18n.t("liquid_tags.null_tag.liquid_tag_is_disabled", tag_name: tag_name)
  end
end

%w[
  assign break capture case cycle decrement echo for
  if ifchanged include increment render tablerow unless
].each do |tag|
  Liquid::Template.register_tag(tag, NullTag)
end
