if Rails.env.production?
  SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(
    fog_provider: "AWS",
    aws_access_key_id: ApplicationConfig["AWS_ID"],
    aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
    fog_directory: ApplicationConfig["AWS_BUCKET_NAME"],
    fog_region: "us-east-1",
  )

  SitemapGenerator::Sitemap.public_path = "tmp/"
  SitemapGenerator::Sitemap.sitemaps_host = "https://thepracticaldev.s3.amazonaws.com/"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
end

SitemapGenerator::Sitemap.default_host = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"

SitemapGenerator::Sitemap.create do
  Article.where(published: true).
    where("reactions_count > ? OR featured = ?", 20, true).
    where(published: true).
    order("last_comment_at DESC").limit(1000).find_each do |article|
    add article.path, lastmod: article.last_comment_at
  end

  User.order("comments_count DESC").where("updated_at > ?", 5.days.ago).limit(250).find_each do |user|
    add "/#{user.username}", changefreq: "daily"
  end

  Tag.order("hotness_score DESC").limit(100).find_each do |tag|
    add "/t/#{tag.name}", changefreq: "daily"
  end
end
