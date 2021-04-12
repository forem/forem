module Homepage
  class FetchTagFlares
    ATTRIBUTES = %i[name bg_color_hex text_color_hex].freeze

    def self.call(articles)
      articles_tag_flares = articles_tag_flares(articles)

      tags = Tag.where(name: articles_tag_flares.keys).select(*ATTRIBUTES).index_by(&:name)

      tag_flares = {}
      articles_tag_flares.each do |tag_name, article_ids|
        article_ids.each do |article_id|
          tag_flares[article_id] = tags[tag_name].as_json(only: ATTRIBUTES)
        end
      end

      tag_flares
    end

    def self.articles_tag_flares(articles)
      flare_tags_for_articles = Hash.new { |hash, key| hash[key] = [] }

      articles.pluck(:id, :cached_tag_list).map do |article_id, cached_tag_list|
        tags = cached_tag_list.split(", ")
        flare_tag = ::Constants::Tags::FLARE_TAG_NAMES.to_set.intersection(tags).first
        next if flare_tag.blank?

        flare_tags_for_articles[flare_tag] << article_id
      end

      flare_tags_for_articles
    end
    private_class_method :articles_tag_flares
  end
end
