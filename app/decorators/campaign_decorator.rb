class CampaignDecorator < ApplicationDecorator
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  def sidebar_image
    return unless active?

    img = image_tag(object.sidebar_image, class: "block w-100 h-auto radius-default", width: 1000, height: 420)
    return link_to(img, url) if url

    img
  end

  def main_tag
    @main_tag ||= featured_tags.first
  end
end
