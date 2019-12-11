module Suggester
  module Articles
    class Classic
      MIN_REACTION_COUNT = Rails.env.production? ? 45 : 1

      attr_accessor :input, :not_ids

      def initialize(input = nil, options = {})
        @input = input
        @not_ids = options[:not_ids]
      end

      def get(num = 1)
        articles = if rand(8) == 1
                     random_high_quality_articles(num)
                   else
                     qualifying_articles(random_supported_tag_names).where.not(id: not_ids).compact.sample(num)
                   end
        articles = random_high_quality_articles(num) if articles.empty?
        articles
      end

      def qualifying_articles(tag_names)
        tag_name = tag_names.sample
        Rails.cache.fetch("classic-article-for-tag-#{tag_name}}", expires_in: 90.minutes) do
          Article.published.cached_tagged_with(tag_name).
            includes(user: [:pro_membership]).
            limited_column_select.
            where(featured: true).
            where("positive_reactions_count > ?", MIN_REACTION_COUNT).
            where("published_at > ?", 10.months.ago).
            order(Arel.sql("RANDOM()"))
        end
      end

      def random_high_quality_articles(num)
        HighQuality.new(not_ids: not_ids).suggest(num)
      end

      def random_supported_tag_names
        if input.class.name == "User"
          input.decorate.cached_followed_tags.
            where(supported: true).
            where.not(name: "ama").
            pluck(:name)
        elsif input.class.name == "Article"
          Tag.where(supported: true, name: input.decorate.cached_tag_list_array).
            where.not(name: "ama").
            pluck(:name)
        else
          ["discuss"]
        end
      end
    end
  end
end
