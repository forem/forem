module Homepage
  module FetchTagFlares
    ATTRIBUTES = %i[name bg_color_hex text_color_hex].freeze

    def self.call(articles)
      flares = articles_tag_flares(articles)

      tags = Tag.where(name: flares.keys).select(*ATTRIBUTES).index_by(&:name)

      flares.each_with_object({}) do |(tag_name, article_ids), tag_flares|
        article_ids.each do |article_id|
          tag_flares[article_id] = tags[tag_name].as_json(only: ATTRIBUTES)
        end
      end
    end

    def self.articles_tag_flares(articles)
      flare_tags_for_articles = Hash.new { |hash, key| hash[key] = [] }

      flare_tag_names = ::Constants::Tags::FLARE_TAG_NAMES.to_set
      articles.pluck(:id, :cached_tag_list).map do |article_id, cached_tag_list|
        tags = cached_tag_list.split(", ")
        flare_tag = flare_tag_names.intersection(tags).first
        next if flare_tag.blank?

        flare_tags_for_articles[flare_tag] << article_id
      end

      flare_tags_for_articles
    end
    private_class_method :articles_tag_flares
  end
end
