module Suggester
  module Articles
    class HighQuality
      MIN_HQ_REACTION_COUNT = Rails.env.production? ? 75 : 1

      def initialize(options = {})
        @not_ids = options[:not_ids]
      end

      def suggest(num)
        Article.published.where(featured: true).
          includes(:user).
          limited_column_select.
          where("positive_reactions_count > ?", MIN_HQ_REACTION_COUNT).
          where.not(id: @not_ids).
          order(Arel.sql("RANDOM()")).
          limit(num)
      end
    end
  end
end
