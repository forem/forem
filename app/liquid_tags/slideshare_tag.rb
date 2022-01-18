class SlideshareTag < LiquidTagBase
  PARTIAL = "liquids/slideshare".freeze

  def initialize(_tag_name, key, _parse_context)
    super
    @key = validate(key.strip)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        key: @key,
        height: 450
      },
    )
  end

  private

  def validate(key)
    unless key.match?(/\A[a-zA-Z0-9]{12,14}\Z/)
      raise StandardError,
            I18n.t("liquid_tags.slideshare_tag.invalid_slideshare_key")
    end

    key
  end
end

Liquid::Template.register_tag("slideshare", SlideshareTag)
