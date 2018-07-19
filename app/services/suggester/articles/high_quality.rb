module Suggester
  module Articles
    class HighQuality
      MIN_HQ_REACTION_COUNT = Rails.env.production? ? 75 : -1

      def initialize(options = {})
        @not_ids = options[:not_ids]
      end

      def suggest
          Article.where(published: true, featured: true).
            includes(:user).
            where("positive_reactions_count > ?", MIN_HQ_REACTION_COUNT).
            order("RANDOM()").
            limited_column_select.
            where.not(id: @not_ids).
            first
      end
    end
  end
end
