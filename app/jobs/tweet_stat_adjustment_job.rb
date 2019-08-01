class TweetStatAdjustmentJob < ApplicationJob
  queue_as :tweet_stat_adjustment

  def perform(article_id)
    article = Article.find_by(id: article_id)
    TweetStatAdjustmentService.new(article.body_markdown.to_s).call
  end
end
