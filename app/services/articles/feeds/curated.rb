module Articles
  module Feeds
    module Curated
      def self.call(tag: nil, number_of_articles: nil, page: 1, user: nil)
        number_of_articles ||= 25

        relation = Articles::Feeds::Tag.call(tag)
          .published.from_subforem
          .favorited
          .order(Arel.sql("articles.favorited_at DESC NULLS LAST, articles.published_at DESC"))
          .includes(:distinct_reaction_categories, :subforem)
          .where("score > -10")

        if user.present? && (hidden_tags = user.cached_antifollowed_tag_names).any?
          relation = relation.not_cached_tagged_with_any(hidden_tags)
        end

        relation.page(page).per(number_of_articles)
      end
    end
  end
end
