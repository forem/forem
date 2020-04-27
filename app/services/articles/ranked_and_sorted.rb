module Articles
  class RankedAndSorted
    attr_reader :articles,
                :user,
                :tag_weight,
                :randomness,
                :comment_weight,
                :number_of_articles,
                :experience_level_weight

    def initialize(options = {})
      @articles = options[:articles]
      @user = options[:user]
      @tag_weight = options[:tag_weight]
      @randomness = options[:randomness]
      @comment_weight = options[:comment_weight]
      @number_of_articles = options[:number_of_articles]
      @experience_level_weight = options[:experience_level_weight]
    end

    def perform
      ranked_articles = articles.each_with_object({}) do |article, result|
        article_points = Articles::Score.new(
          article: article,
          user: user,
          tag_weight: tag_weight,
          randomness: randomness,
          comment_weight: comment_weight,
          experience_level_weight: experience_level_weight,
        ).score_single_article
        result[article] = article_points
      end
      ranked_articles = ranked_articles.sort_by { |_article, article_points| -article_points }.map(&:first)
      ranked_articles.to(number_of_articles - 1)
    end
  end
end
