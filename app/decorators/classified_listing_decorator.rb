class ClassifiedListingDecorator < ApplicationDecorator
  DEFAULT_COLOR = "#000000".freeze

  def social_preview_category
    category = object.classified_listing_category
    category.social_preview_description.presence || category.name
  end

  def social_preview_color(brightness: 1.0)
    category = object.classified_listing_category
    color = category.social_preview_color.presence || DEFAULT_COLOR
    HexComparer.new([color]).brightness(brightness)
  end
end
