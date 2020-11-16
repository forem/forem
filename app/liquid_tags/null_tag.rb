class NullTag < Liquid::Block
  def initialize(tag_name, _markup, _options) # rubocop:disable Lint/MissingSuper
    raise StandardError, "Liquid##{tag_name} tag is disabled"
  end
end

disabled_tags = %w[assign break capture case cycle decrement for if ifchanged include increment unless tablerow]

disabled_tags.each do |tag|
  Liquid::Template.register_tag(tag, NullTag)
end
