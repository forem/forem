module Search
  class TagSerializer < ApplicationSerializer
    attributes :id, :name, :hotness_score, :supported, :short_summary, :rules_html, :bg_color_hex
    attribute :badge do |tag|
      if tag.badge
        { badge_image: tag.badge.badge_image }
      end
    end
  end
end
