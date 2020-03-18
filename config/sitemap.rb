if Rails.env.production?
  region = ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
  SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(
    fog_provider: "AWS",
    aws_access_key_id: ApplicationConfig["AWS_ID"],
    aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
    fog_directory: ApplicationConfig["AWS_BUCKET_NAME"],
    fog_region: region,
  )
  SitemapGenerator::Sitemap.sitemaps_host = "https://#{ApplicationConfig['AWS_BUCKET_NAME']}.s3.amazonaws.com/"
  SitemapGenerator::Sitemap.public_path = "tmp/"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
end

SitemapGenerator::Sitemap.default_host = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"

# Base sitemap
SitemapGenerator::Sitemap.create do
  Article.published.where("score > ? OR featured = ?", 12, true).
    limit(38_000).find_each do |article|
    add article.path, lastmod: article.last_comment_at, changefreq: "daily"
  end

  User.order("comments_count DESC").where("updated_at > ?", 5.days.ago).limit(8000).find_each do |user|
    add "/#{user.username}", changefreq: "daily"
  end

  Tag.order("hotness_score DESC").limit(250).find_each do |tag|
    add "/t/#{tag.name}", changefreq: "daily"
  end
end

60.times do |n|
  date = n.months.ago
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{date.strftime('%b%y').downcase}/"
  SitemapGenerator::Sitemap.create do
    Article.published.where("score > ? OR featured = ?", 4, true).
      where("published_at > ?", date.at_beginning_of_month).
      limit(45_000).find_each do |article|
      add article.path, lastmod: article.last_comment_at, changefreq: "daily"
    end
  end
end
# d.strftime("%b")
