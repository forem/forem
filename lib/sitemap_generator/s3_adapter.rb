# TEMPORARY
# Until https://github.com/kjvarga/sitemap_generator/pull/359 is merged
# We have to monkey patch the S3Adapter to allow for the fog_public option to be set
module SitemapGenerator
  # https://github.com/kjvarga/sitemap_generator/blob/master/lib/sitemap_generator/adapters/s3_adapter.rb
  class S3Adapter
    def initialize(opts = {}) # rubocop:disable Style/OptionHash
      @aws_access_key_id = opts[:aws_access_key_id] || ENV.fetch("AWS_ACCESS_KEY_ID", nil)
      @aws_secret_access_key = opts[:aws_secret_access_key] || ENV.fetch("AWS_SECRET_ACCESS_KEY", nil)
      @fog_provider = opts[:fog_provider] || ENV.fetch("FOG_PROVIDER", nil)
      @fog_directory = opts[:fog_directory] || ENV.fetch("FOG_DIRECTORY", nil)
      @fog_region = opts[:fog_region] || ENV.fetch("FOG_REGION", nil)
      @fog_path_style = opts[:fog_path_style] || ENV.fetch("FOG_PATH_STYLE", nil)
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
