class SponsorshipDecorator < ApplicationDecorator
  def level_background_color
    hexes = {
      "gold" => "linear-gradient(to right, #faf0e6 8%, #faf3e6 18%, #fcf6eb 33%);",
      "silver" => "linear-gradient(to right, #e3e3e3 8%, #f0eded 18%, #e8e8e8 33%);",
      "bronze" => "linear-gradient(to right, #ebe2d3 8%, #f5eee1 18%, #ede6d8 33%);"
    }

    hexes[level].to_s
  end
end
