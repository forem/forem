module Search
  class TagSerializer
    include FastJsonapi::ObjectSerializer

    attributes :id, :name, :hotness_score, :supported, :short_summary, :rules_html
  end
end
