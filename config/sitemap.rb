# TEMPORARY
# Until https://github.com/kjvarga/sitemap_generator/pull/359 is merged
# We have to monkey patch the S3Adapter to allow for the fog_public option to be set
module SitemapGenerator
  # https://github.com/kjvarga/sitemap_generator/blob/master/lib/sitemap_generator/adapters/s3_adapter.rb
  class S3Adapter
    def initialize(opts = {}) # rubocop:disable Style/OptionHash
      @aws_access_key_id = opts[:aws_access_key_id] || ENV["AWS_ACCESS_KEY_ID"]
      @aws_secret_access_key = opts[:aws_secret_access_key] || ENV["AWS_SECRET_ACCESS_KEY"]
      @fog_provider = opts[:fog_provider] || ENV["FOG_PROVIDER"]
      @fog_directory = opts[:fog_directory] || ENV["FOG_DIRECTORY"]
      @fog_region = opts[:fog_region] || ENV["FOG_REGION"]
      @fog_path_style = opts[:fog_path_style] || ENV["FOG_PATH_STYLE"]
      @fog_storage_options = opts[:fog_storage_options] || {}
      @fog_public = opts[:fog_public].to_s.present? ? opts[:fog_public] : true # additional line
    end

    # Call with a SitemapLocation and string data
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      credentials = { provider: @fog_provider }

      if @aws_access_key_id && @aws_secret_access_key
        credentials[:aws_access_key_id] = @aws_access_key_id
        credentials[:aws_secret_access_key] = @aws_secret_access_key
      else
        credentials[:use_iam_profile] = true
      end

      credentials[:region] = @fog_region if @fog_region
      credentials[:path_style] = @fog_path_style if @fog_path_style

      storage   = Fog::Storage.new(@fog_storage_options.merge(credentials))
      directory = storage.directories.new(key: @fog_directory)
      directory.files.create(
        key: location.path_in_public,
        body: File.open(location.path),
        public: @fog_public, # additional line
      )
    end
  end
end

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
