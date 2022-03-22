class CampaignDecorator < ApplicationDecorator
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  def sidebar_image(options)
    return unless show_in_sidebar?

    image_url = Images::Optimizer.call(object.sidebar_image, width: 500)
    img = image_tag(image_url, options)
    return link_to(img, url) if url

    img
  end

  def header_text(count)
    if display_name.present?
      "#{Campaign.current.display_name} (#{count})"
    else
      I18n.t("views.campaign.subtitle", count: count)
    end
  end

  def main_tag
    @main_tag ||= featured_tags.first
  end
end
