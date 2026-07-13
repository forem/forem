json.type_of "trend"

json.extract!(
  trend,
  :id,
  :name,
  :slug,
  :description,
  :key_questions,
  :score,
  :articles_count,
  :cover_image
)

json.first_observed_at utc_iso_timestamp(trend.first_observed_at)
json.last_observed_at  utc_iso_timestamp(trend.last_observed_at)
json.created_at        utc_iso_timestamp(trend.created_at)
json.updated_at        utc_iso_timestamp(trend.updated_at)

json.top_articles trend.top_articles(3) do |article|
  json.extract! article, :id, :title, :slug, :score, :published_at
end
