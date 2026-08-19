json.partial! "api/v1/shared/trend", trend: @trend

json.top_articles @trend.top_articles(3) do |article|
  json.extract! article, :id, :title, :slug, :score, :published_at
end
