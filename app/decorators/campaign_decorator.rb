class CampaignDecorator < ApplicationDecorator
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  def sidebar_image(options)
    return unless show_in_sidebar?

    img = image_tag(object.sidebar_image, options)
    return link_to(img, url) if url

    img
  end

  def main_tag
    @main_tag ||= featured_tags.first
  end
end
