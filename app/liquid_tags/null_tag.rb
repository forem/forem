class NullTag < Liquid::Block
  def initialize(tag_name, _markup, _options) # rubocop:disable Lint/MissingSuper
    raise StandardError, "Liquid##{tag_name} tag is disabled"
  end
end

%w[
  assign break capture case cycle decrement echo for
  if ifchanged include increment render tablerow unless
].each do |tag|
  Liquid::Template.register_tag(tag, NullTag)
end
