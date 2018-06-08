module Suggester
  module Articles
    class Boosted
      attr_accessor :user, :article, :tags, :not_ids, :area

      def initialize(user, article, options)
        @user = user
        @article = article
        @tags = (user&.cached_followed_tag_names.to_a + article.decorate.cached_tag_list_array)
        @not_ids = options[:not_ids]
        @area = options[:area]
      end

      def suggest
        base_articles = Article.includes(:user).
          includes(:organization).
          where.not(id: not_ids, organization_id: nil).
          tagged_with(tags + article.boosted_additional_tags.split, any: true)

        if area == "additional_articles"
          base_articles.boosted_via_additional_articles.sample
        else
          base_articles.boosted_via_dev_digest_email.sample
        end
      end
    end
  end
end
