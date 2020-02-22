class BufferedArticlesController < ApplicationController
  # No authorization required for entirely public controller

  def index
    render json: { urls: buffered_articles_urls }.to_json
  end

  private

  def buffered_articles_urls
    relation = if Rails.env.production?
                 Article.where("last_buffered > ? OR published_at > ?", 24.hours.ago, 20.minutes.ago)
               else
                 Article.all
               end

    paths = relation.pluck(:path)
    paths.map { |path| "https://#{ApplicationConfig['APP_DOMAIN']}#{path}" }
  end
end
