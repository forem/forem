class BufferedArticlesController < ApplicationController
  # No authorization required for entirely public controller
  def index
    @article_urls = buffered_article_urls
    render json: {
      urls: @article_urls
    }.to_json
  end

  def buffered_article_urls
    if Rails.env.production?
      Article.
        where("last_buffered > ? OR published_at > ?", 24.hours.ago, 20.minutes.ago).
        map { |a| "https://#{ApplicationConfig['APP_DOMAIN']}#{a.path}" }
    else
      Article.all.map { |a| "https://#{ApplicationConfig['APP_DOMAIN']}#{a.path}" }
    end
  end
end
