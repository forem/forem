module CarrierWaveInitializer
  # Bound S3 socket timeouts and retries so a stalled connection fails fast
  # instead of consuming the entire 30s Rack::Timeout request budget (Excon
  # defaults to 60s connect/read/write timeouts and fog-aws defaults to 5 retries).
  FOG_CONNECTION_OPTIONS = {
    connect_timeout: 5,
    read_timeout: 10,
    write_timeout: 10,
    retry_limit: 2
  }.freeze

  CONFIG_IVARS = %i[
    @enable_processing
    @move_to_store
    @asset_host
    @fog_directory
    @fog_attributes
    @fog_public
    @fog_credentials
  ].freeze

  def self.local_storage_config
    configure_carrierwave do |config|
      config.storage = :file
      config.cache_storage = :file
      config.enable_processing = !Rails.env.test? # disabled for test
      config.move_to_store = Rails.env.test?
      config.asset_host = if Rails.env.production?
                            "https://#{ApplicationConfig['APP_DOMAIN']}"
                          end
      config.fog_directory = nil
      config.fog_attributes = {}
      config.fog_public = true
      config.fog_credentials = {}
    end
  end

  def self.standard_production_config
    configure_carrierwave do |config|
      config.storage = :fog
      # Cache processed workfiles on local disk before storing to S3 (restoring
      # CarrierWave 2.x behavior) so store! issues a single S3 PUT instead of
      # PUT (tmp) + COPY (store) + DELETE (tmp).
      config.cache_storage = :file
      config.enable_processing = !Rails.env.test?
      config.move_to_store = false
      config.asset_host = nil
      config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
      config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
      config.fog_public = true
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ApplicationConfig["AWS_ID"],
        aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
        region: ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"],
        connection_options: FOG_CONNECTION_OPTIONS
      }
    end
  end

  def self.forem_cloud_config
    configure_carrierwave do |config|
      config.storage = :fog
      config.cache_storage = :file
      config.enable_processing = !Rails.env.test?
      config.move_to_store = false
      config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
      config.fog_attributes = {}
      config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/remoteimages"
      config.fog_public = false
      config.fog_credentials = {
        provider: "AWS",
        use_iam_profile: true,
        region: "us-east-2",
        connection_options: FOG_CONNECTION_OPTIONS
      }
    end
  end

  def self.configure_carrierwave(&block)
    CarrierWave.configure(&block)
    reset_descendant_configs!
  end

  # CarrierWave's `add_config` macro memoizes superclass config values into class
  # instance variables (`@asset_host`, `@fog_public`, etc.) on any subclass the
  # first time that subclass reads them. Clearing those cached ivars on descendants
  # ensures re-initializing or switching storage modes propagates to all uploaders.
  def self.reset_descendant_configs!
    CarrierWave::Uploader::Base.descendants.each do |subclass|
      subclass._storage = CarrierWave::Uploader::Base._storage
      subclass._cache_storage = CarrierWave::Uploader::Base._cache_storage
      CONFIG_IVARS.each do |ivar|
        subclass.remove_instance_variable(ivar) if subclass.instance_variable_defined?(ivar)
      end
    end
  end

  def self.initialize!
    if Rails.env.production? && ENV["FILE_STORAGE_LOCATION"] != "file"
      if ENV["FOREM_CONTEXT"] == "forem_cloud"
        forem_cloud_config
      elsif ApplicationConfig["AWS_ID"].present?
        standard_production_config
      else
        local_storage_config
      end
    else
      local_storage_config
    end
  end
end

Rails.application.reloader.to_prepare do
  CarrierWaveInitializer.initialize!
end
