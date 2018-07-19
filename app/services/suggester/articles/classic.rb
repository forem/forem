module Suggester
  module Articles
    class Classic
      MIN_REACTION_COUNT = Rails.env.production? ? 45 : 1

      attr_accessor :input, :not_ids
      def initialize(input = nil, options = {})
        @input = input
        @not_ids = options[:not_ids]
      end

      def get(tag_names = random_supported_tag_names)
        if rand(8) == 1
          random_high_quality_article
        else
          qualifying_articles(tag_names).where.not(id: not_ids).compact.sample ||
            random_high_quality_article
        end
      end

      def qualifying_articles(tag_names)
        tag_name = tag_names.sample
        Rails.cache.
          fetch("classic-article-for-tag-#{tag_name}}", expires_in: 90.minutes) do
          Article.tagged_with(tag_name).
            includes(:user).
            limited_column_select.
            where(published: true, featured: true).
            where("positive_reactions_count > ?", MIN_REACTION_COUNT).
            where("published_at > ?", 10.months.ago).
            order("RANDOM()")
        end
      end

      def random_high_quality_article
        HighQuality.new(not_ids: not_ids).suggest
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
