class MediumTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include InlineSvg::ActionView::Helpers
  attr_reader :response

  PARTIAL = "liquids/medium".freeze
  REGISTRY_REGEXP = %r{https://(?:\w+.)?medium.com/(?:@\w+/)?[\w-]+}

  def initialize(_tag_name, url, _parse_context)
    super
    @response = parse_url(strip_tags(url))
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        response: @response
      },
    )
  end

  private

  def parse_url(url)
    match = pattern_match_for(url, [REGISTRY_REGEXP])
    raise StandardError, I18n.t("liquid_tags.medium_tag.invalid_link_url") unless match

    MediumArticleRetrievalService.new(url).call
  rescue StandardError
    raise_error
  end

  def raise_error
    raise StandardError, I18n.t("liquid_tags.medium_tag.invalid_link_url")
  end
end

Liquid::Template.register_tag("medium", MediumTag)

UnifiedEmbed.register(MediumTag, regexp: MediumTag::REGISTRY_REGEXP)
