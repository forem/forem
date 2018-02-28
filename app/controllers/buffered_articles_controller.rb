class BufferedArticlesController < ApplicationController
  def index
    @article_urls = buffered_article_urls
    render json: {
      urls: @article_urls,
    }.to_json
  end

  def buffered_article_urls
    if Rails.env.production?
      Article.
        where("last_buffered > ?", 24.hours.ago).
        map { |a| "https://dev.to#{a.path}" }
    else
      Article.all.map { |a| "https://dev.to#{a.path}" }
    end
  end
end
