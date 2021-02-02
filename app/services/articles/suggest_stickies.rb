module Articles
  class SuggestStickies
    SUGGESTION_TAGS = %w[career productivity discuss explainlikeimfive].freeze

    def self.call(article)
      new(article).call
    end

    def initialize(article)
      @article = article
      @reaction_count_num = Rails.env.production? ? 15 : -1
      @comment_count_num = Rails.env.production? ? 7 : -2
    end

    def call
      (tag_articles.load + more_articles).sample(3)
    end

    private

    attr_accessor :article, :reaction_count_num, :comment_count_num

    def tag_articles
      article_tags = article.cached_tag_list_array - ["discuss"]

      Article
        .published
        .tagged_with(article_tags, any: true).unscope(:select)
        .limited_column_select
        .where("public_reactions_count > ? OR comments_count > ?", reaction_count_num, comment_count_num)
        .where.not(id: article.id)
        .where.not(user_id: article.user_id)
        .where("featured_number > ?", 5.days.ago.to_i)
        .order(Arel.sql("RANDOM()"))
        .limit(3)
    end

    def more_articles
      return [] if tag_articles.size > 6

      Article
        .published
        .tagged_with(SUGGESTION_TAGS, any: true).unscope(:select)
        .limited_column_select
        .where("comments_count > ?", comment_count_num)
        .where.not(id: article.id)
        .where.not(user_id: article.user_id)
        .where("featured_number > ?", 5.days.ago.to_i)
        .order(Arel.sql("RANDOM()"))
        .limit(10 - tag_articles.size)
    end
  end
end
