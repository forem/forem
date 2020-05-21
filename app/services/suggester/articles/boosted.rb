module Suggester
  module Articles
    class Boosted
      attr_accessor :tag, :not_ids, :area

      def initialize(tag, options)
        @tag = tag
        @not_ids = options[:not_ids]
        @area = options[:area]
      end

      def suggest
        base_articles = Article.includes(:user).
          includes(:organization).
          where.not(id: not_ids, organization_id: nil).
          cached_tagged_with(tag)

        if area == "additional_articles"
          base_articles.boosted_via_additional_articles.sample
        else
          base_articles.boosted_via_dev_digest_email.sample
        end
      end
    end
  end
end
