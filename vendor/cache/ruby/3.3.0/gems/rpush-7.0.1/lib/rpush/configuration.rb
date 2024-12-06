require 'pathname'
require 'ostruct'

module Rpush
  class << self
    attr_writer :config

    def config
      @config ||= Rpush::Configuration.new
    end

    def configure
      return unless block_given?
      yield config
      config.initialize_client
    end
  end

  CURRENT_ATTRS = [:push_poll, :embedded, :pid_file, :batch_size, :push, :client, :logger, :log_file, :foreground, :foreground_logging, :log_level, :plugin, :apns]
  DEPRECATED_ATTRS = []
  CONFIG_ATTRS = CURRENT_ATTRS + DEPRECATED_ATTRS

  class ConfigurationError < StandardError; end

  class ApnsFeedbackReceiverConfiguration < Struct.new(:frequency, :enabled) # rubocop:disable Style/StructInheritance
    def initialize
      super
      self.enabled = true
      self.frequency = 60
    end
  end

  class ApnsConfiguration < Struct.new(:feedback_receiver) # rubocop:disable Style/StructInheritance
    def initialize
      super
      self.feedback_receiver = ApnsFeedbackReceiverConfiguration.new
    end
  end

  class Configuration < Struct.new(*CONFIG_ATTRS) # rubocop:disable Style/StructInheritance
    include Deprecatable

    delegate :redis_options, to: '::Modis'

    def initialize
      super

      self.push_poll = 2
      self.batch_size = 100
      self.logger = nil
      self.log_file = 'log/rpush.log'
      self.pid_file = 'tmp/rpush.pid'
      self.log_level = (defined?(Rails) && Rails.logger) ? Rails.logger.level : ::Logger::Severity::DEBUG
      self.plugin = OpenStruct.new
      self.foreground = false
      self.foreground_logging = true

      self.apns = ApnsConfiguration.new

      # Internal options.
      self.embedded = false
      self.push = false
    end

    def update(other)
      CONFIG_ATTRS.each do |attr|
        other_value = other.send(attr)
        send("#{attr}=", other_value) unless other_value.nil?
      end
    end

    def pid_file=(path)
      if path && !Pathname.new(path).absolute?
        super(File.join(Rpush.root, path))
      else
        super
      end
    end

    def log_file=(path)
      if path && !Pathname.new(path).absolute?
        super(File.join(Rpush.root, path))
      else
        super
      end
    end

    def logger=(logger)
      super(logger)
    end

    def client=(client)
      super
      initialize_client
    end

    def redis_options=(options)
      Modis.redis_options = options if client == :redis
    end

    def initialize_client
      return if @client_initialized
      raise ConfigurationError, 'Rpush.config.client is not set.' unless client
      require "rpush/client/#{client}"

      client_module = Rpush::Client.const_get(client.to_s.camelize)
      Rpush.send(:include, client_module) unless Rpush.ancestors.include?(client_module)

      [:Apns, :Gcm, :Wpns, :Wns, :Adm, :Pushy, :Webpush].each do |service|
        Rpush.const_set(service, client_module.const_get(service)) unless Rpush.const_defined?(service)
      end

      @client_initialized = true
    end
  end
end
