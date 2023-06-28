module Articles
  class SuggestStickies
    # @todo Should we make this configurable in the admin interface?
    SUGGESTION_TAGS = %w[career productivity discuss explainlikeimfive].freeze

    DEFAULT_TAG_ARTICLES_LIMIT = 3
    DEFAULT_MORE_ARTICLES_LIMIT = 7

    # @api public
    #
    # A set of suggested articles related to the given :article.
    #
    # @param article [ArticleDecorator]
    # @param sample_size [Integer] How many Articles in the return set?
    #
    # @return [Array<Article>] An array Article records
    #
    # @note The resulting array of articles will be 30% articles that
    #       share tags with the given article, and 70% of articles
    #       that have tags in the SUGGESTION_TAGS constant.  These
    #       percentages are related to the DEFAULT_TAG_ARTICLES_LIMIT
    #       and DEFAULT_MORE_ARTICLES_LIMIT.
    def self.call(article, sample_size: 3)
      new(article, sample_size: sample_size).call
    end

    def initialize(article, sample_size:)
      @article = article
      @reaction_count_num = Rails.env.production? ? 15 : -1
      @comment_count_num = Rails.env.production? ? 7 : -2
      @sample_size = sample_size
    end

    def call
      (tag_articles + more_articles).sample(@sample_size)
    end

    private

    attr_accessor :article, :reaction_count_num, :comment_count_num

    def tag_articles
      article_tags = article.cached_tag_list_array - ["discuss"]

      scope = Article
        .where("public_reactions_count > ? OR comments_count > ?", reaction_count_num, comment_count_num)
        .limit(DEFAULT_TAG_ARTICLES_LIMIT)

      apply_common_scope(scope: scope, tags: article_tags)
    end

    # @note This previously used a `.limit(10 - tag_articles.count)`,
    #       which meant we were running an unnecessary count query.
    #       We also had a guard clause that said if we have more than
    #       6 tag_articles, we should return an empty array.  However,
    #       with the initial limit of 3 for tag articles, that guard
    #       was unnecessary.
    def more_articles
      scope = Article
        .where("comments_count > ?", comment_count_num)
        .limit(DEFAULT_MORE_ARTICLES_LIMIT)

      apply_common_scope(scope: scope, tags: SUGGESTION_TAGS)
    end

    # A helper method to ensure a consistent lookup
    def apply_common_scope(scope:, tags:)
      scope.published
        .cached_tagged_with_any(tags)
        .unscope(:select)
        .limited_column_select
        .where.not(id: article.id)
        .not_authored_by(article.user_id)
        .where("published_at > ?", 5.days.ago)
        .order(Arel.sql("RANDOM()"))
    end
  end
end
