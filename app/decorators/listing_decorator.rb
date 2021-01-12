class ListingDecorator < ApplicationDecorator
  DEFAULT_COLOR = "#000000".freeze

  def social_preview_category
    category = object.listing_category
    category.social_preview_description.presence || category.name
  end

  def social_preview_color(brightness: 1.0)
    category = object.listing_category
    color = category.social_preview_color.presence || DEFAULT_COLOR
    Color::CompareHex.new([color]).brightness(brightness)
  end
end
