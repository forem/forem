module Search
  class TagSerializer < ApplicationSerializer
    attributes :id, :name, :hotness_score, :supported, :short_summary, :rules_html, :bg_color_hex, :badge
  end
end
