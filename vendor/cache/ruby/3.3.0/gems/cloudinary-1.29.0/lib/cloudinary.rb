# Copyright Cloudinary
if RUBY_VERSION > "2"
  require "ostruct"
else
  require "cloudinary/ostruct2"
end

require "pathname"
require "yaml"
require "uri"
require "erb"
require "cloudinary/version"
require "cloudinary/exceptions"
require "cloudinary/missing"

module Cloudinary
  autoload :Utils, 'cloudinary/utils'
  autoload :Uploader, 'cloudinary/uploader'
  autoload :BaseConfig, "cloudinary/base_config"
  autoload :Config, "cloudinary/config"
  autoload :AccountConfig, "cloudinary/account_config"
  autoload :BaseApi, "cloudinary/base_api"
  autoload :Api, "cloudinary/api"
  autoload :AccountApi, "cloudinary/account_api"
  autoload :Downloader, "cloudinary/downloader"
  autoload :Blob, "cloudinary/blob"
  autoload :PreloadedFile, "cloudinary/preloaded_file"
  autoload :Static, "cloudinary/static"
  autoload :CarrierWave, "cloudinary/carrier_wave"
  autoload :Search, "cloudinary/search"
  autoload :SearchFolders, "cloudinary/search_folders"

  CF_SHARED_CDN         = "d3jpl91pxevbkh.cloudfront.net"
  AKAMAI_SHARED_CDN     = "res.cloudinary.com"
  OLD_AKAMAI_SHARED_CDN = "cloudinary-a.akamaihd.net"
  SHARED_CDN            = AKAMAI_SHARED_CDN

  USER_AGENT      = "CloudinaryRuby/#{VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"
  @@user_platform = defined?(Rails.version) ? "Rails/#{Rails.version}" : ""

  # Add platform information to the USER_AGENT header
  # This is intended for platform information and not individual applications!
  def self.user_platform=(value)
    @@user_platform= value
  end

  def self.user_platform
    @@user_platform
  end

  def self.USER_AGENT
    if @@user_platform.empty?
      USER_AGENT
    else
      "#{@@user_platform} #{USER_AGENT}"
    end
  end

  FORMAT_ALIASES = {
    "jpeg" => "jpg",
    "jpe"  => "jpg",
    "tif"  => "tiff",
    "ps"   => "eps",
    "ept"  => "eps"
  }

  # Cloudinary config
  #
  # @param [Hash] new_config If +new_config+ is passed, Config will be updated with it
  # @yieldparam [OpenStruct] Config can be updated in the block
  #
  # @return [OpenStruct]
  def self.config(new_config=nil)
    @@config ||= make_new_config(Config)

    @@config.update(new_config) if new_config
    yield @@config if block_given?

    @@config
  end

  # Cloudinary account config
  #
  # @param [Hash] new_config If +new_config+ is passed, Account Config will be updated with it
  # @yieldparam [OpenStruct] Account config can be updated in the block
  #
  # @return [OpenStruct]
  def self.account_config(new_config=nil)
    @@account_config ||= make_new_config(AccountConfig)

    @@account_config.update(new_config) if new_config
    yield @@account_config if block_given?

    @@account_config
  end

  def self.config_from_url(url)
    config.load_from_url(url)
  end

  def self.config_from_account_url(url)
    account_config.load_from_url(url)
  end

  def self.app_root
    if defined? Rails::root
      # Rails 2.2 return String for Rails.root
      Rails.root.is_a?(Pathname) ? Rails.root : Pathname.new(Rails.root)
    else
      Pathname.new(".")
    end
  end

  private

  def self.config_env
    return ENV["CLOUDINARY_ENV"] if ENV["CLOUDINARY_ENV"]
    return Rails.env if defined? Rails::env
    nil
  end

  def self.config_dir
    return Pathname.new(ENV["CLOUDINARY_CONFIG_DIR"]) if ENV["CLOUDINARY_CONFIG_DIR"]
    self.app_root.join("config")
  end

  def self.set_config(new_config)
    new_config.each{|k,v| @@config.send(:"#{k}=", v) if !v.nil?}
  end

  # Builds config from yaml file, extends it with specific module and loads configuration from environment variable
  #
  # @param [Module] config_module Config is extended with this module after being built
  #
  # @return [OpenStruct]
  def self.make_new_config(config_module)
    import_settings_from_file.tap do |config|
      config.extend(config_module)
      config.load_config_from_env
    end
  end

  private_class_method :make_new_config

  # Import settings from yaml file
  #
  # @return [OpenStruct]
  def self.import_settings_from_file
    yaml_env_config = begin
      yaml_source = ERB.new(IO.read(config_dir.join("cloudinary.yml"))).result
      yaml_config = if YAML.respond_to?(:safe_load)
                      YAML.safe_load(yaml_source, aliases: true)
                    else
                      YAML.load(yaml_source)
                    end
      yaml_config[config_env]
    rescue StandardError
      {}
    end
    OpenStruct.new(yaml_env_config)
  end

  private_class_method :import_settings_from_file
end
  # Prevent require loop if included after Rails is already initialized.
  require "cloudinary/helper" if defined?(::ActionView::Base)
  require "cloudinary/cloudinary_controller" if defined?(::ActionController::Base)
  require "cloudinary/railtie" if defined?(Rails) && defined?(Rails::Railtie)
  require "cloudinary/engine" if defined?(Rails) && defined?(Rails::Engine)

