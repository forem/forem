require "sitemap_generator/s3_adapter"

if Rails.env.production?
  region = ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
  config_hash = if ENV["FOREM_CONTEXT"] == "forem_cloud" # @forem/systems jdoss's special sauce.
                  # Excluding the aws_access_key_id and aws_secret_access_key causes use_iam_profile
                  # to be set to true by the S3Adapter
                  # https://github.com/kjvarga/sitemap_generator/blob/0b847f1e7a544ea8ef87bb643a732e30a07a14c9/lib/sitemap_generator/adapters/s3_adapter.rb#L39
                  {
                    fog_provider: "AWS",
                    fog_directory: ApplicationConfig["AWS_BUCKET_NAME"],
                    fog_region: "us-east-2",
                    fog_public: false
                  }
                else
                  {
                    fog_provider: "AWS",
                    aws_access_key_id: ApplicationConfig["AWS_ID"],
                    aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
                    fog_directory: ApplicationConfig["AWS_BUCKET_NAME"],
                    fog_region: region
                  }
                end

  SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(config_hash)
  SitemapGenerator::Sitemap.sitemaps_host = "https://#{ApplicationConfig['AWS_BUCKET_NAME']}.s3.amazonaws.com/"
  SitemapGenerator::Sitemap.public_path = "tmp/"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
end

SitemapGenerator::Sitemap.default_host = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"

SitemapGenerator::Sitemap.create do
  Article.published.where("score > ? OR featured = ?", 12, true)
    .limit(38_000).find_each do |article|
    add article.path, lastmod: article.last_comment_at, changefreq: "daily"
  end

  User.order(comments_count: :desc).where("updated_at > ?", 5.days.ago).limit(8000).find_each do |user|
    add "/#{user.username}", changefreq: "daily"
  end

  Tag.order(hotness_score: :desc).limit(250).find_each do |tag|
    add "/t/#{tag.name}", changefreq: "daily"
  end
end
