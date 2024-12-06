require 'pathname'
require 'delegate'
require 'logger'
require 'fileutils'
require 'openssl'

require 'honeybadger/version'
require 'honeybadger/logging'
require 'honeybadger/backend'
require 'honeybadger/config/defaults'
require 'honeybadger/util/http'
require 'honeybadger/util/revision'
require 'honeybadger/logging'

module Honeybadger
  # @api private
  # The Config class is used to manage Honeybadger's initialization and
  # configuration.
  class Config
    extend Forwardable

    include Logging::Helper

    class ConfigError < StandardError; end

    # Config subclasses have circular dependencies, so they must be loaded
    # after constants are defined.
    autoload :Env, 'honeybadger/config/env'
    autoload :Yaml, 'honeybadger/config/yaml'
    autoload :Ruby, 'honeybadger/config/ruby'

    KEY_REPLACEMENT = Regexp.new('[^a-z\d_]', Regexp::IGNORECASE).freeze

    DOTTED_KEY = Regexp.new('\A([^\.]+)\.(.+)\z').freeze

    NOT_BLANK = Regexp.new('\S').freeze

    IVARS = [:@ruby, :@env, :@yaml, :@framework].freeze

    def initialize(opts = {})
      @ruby = opts.freeze
      @env = {}.freeze
      @yaml = {}.freeze
      @framework = {}.freeze
    end

    attr_accessor :ruby, :env, :yaml, :framework

    # Called by framework (see lib/honeybadger/init/) at the point of
    # initialization. This is not required for the notifier to work (i.e. with
    # `require 'honeybadger/ruby'`).
    def init!(opts = {}, env = ENV)
      load!(framework: opts, env: env)

      init_logging!
      init_backend!

      logger.info(sprintf('Initializing Honeybadger Error Tracker for Ruby. Ship it! version=%s framework=%s', Honeybadger::VERSION, detected_framework))
      logger.warn('Development mode is enabled. Data will not be reported until you deploy your app.') if warn_development?

      self
    end

    def load!(framework: {}, env: ENV)
      return self if @loaded
      self.framework = framework.freeze
      self.env = Env.new(env).freeze
      load_config_from_disk {|yaml| self.yaml = yaml.freeze }
      detect_revision!
      @loaded = true
      self
    end

    def configure
      new_ruby = Ruby.new(self)
      yield(new_ruby)
      self.ruby = ruby.merge(new_ruby).freeze
      @logger = @backend = nil
      self
    end

    def backtrace_filter(&block)
      if block_given?
        warn('DEPRECATED: backtrace_filter is deprecated. Please use before_notify instead. See https://docs.honeybadger.io/ruby/support/v4-upgrade#backtrace_filter')
        self[:backtrace_filter] = block
      end

      self[:backtrace_filter]
    end

    def before_notify_hooks
      (ruby[:before_notify] || []).clone
    end

    def exception_filter(&block)
      if block_given?
        warn('DEPRECATED: exception_filter is deprecated. Please use before_notify instead. See https://docs.honeybadger.io/ruby/support/v4-upgrade#exception_filter')
        self[:exception_filter] = block
      end

      self[:exception_filter]
    end

    def exception_fingerprint(&block)
      if block_given?
        warn('DEPRECATED: exception_fingerprint is deprecated. Please use before_notify instead. See https://docs.honeybadger.io/ruby/support/v4-upgrade#exception_fingerprint')
        self[:exception_fingerprint] = block
      end

      self[:exception_fingerprint]
    end

    def get(key)
      IVARS.each do |var|
        source = instance_variable_get(var)
        if source.has_key?(key)
          return source[key]
        end
      end

      DEFAULTS[key]
    end
    alias [] :get

    def set(key, value)
      self.ruby = ruby.merge(key => value).freeze
      @logger = @backend = nil
    end
    alias []= :set

    def to_hash(defaults = false)
      hash = [:@ruby, :@env, :@yaml, :@framework].reverse.reduce({}) do |a,e|
        a.merge!(instance_variable_get(e))
      end

      hash = DEFAULTS.merge(hash) if defaults

      undotify_keys(hash.select {|k,v| DEFAULTS.has_key?(k) })
    end
    alias to_h to_hash

    # Internal Helpers


    def logger
      init_logging! unless @logger
      @logger
    end

    def backend
      init_backend! unless @backend
      @backend
    end

    def backend=(backend)
      set(:backend, backend)
      @backend = nil
    end

    def dev?
      self[:env] && Array(self[:development_environments]).include?(self[:env])
    end

    def warn_development?
      dev? && backend.kind_of?(Backend::Null)
    end

    def public?
      return true if self[:report_data]
      return false if self[:report_data] == false
      !self[:env] || !dev?
    end

    def debug?
      !!self[:debug]
    end

    def log_debug?
      return debug? if self[:'logging.debug'].nil?
      !!self[:'logging.debug']
    end

    def ignored_classes
      ignore_only = get(:'exceptions.ignore_only')
      return ignore_only if ignore_only
      return DEFAULTS[:'exceptions.ignore'] unless ignore = get(:'exceptions.ignore')

      DEFAULTS[:'exceptions.ignore'] | Array(ignore)
    end

    def ca_bundle_path
      if self[:'connection.system_ssl_cert_chain'] && File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE)
        OpenSSL::X509::DEFAULT_CERT_FILE
      elsif self[:'connection.ssl_ca_bundle_path']
        self[:'connection.ssl_ca_bundle_path']
      else
        local_cert_path
      end
    end

    def local_cert_path
      File.expand_path(File.join('..', '..', '..', 'resources', 'ca-bundle.crt'), __FILE__)
    end

    def connection_port
      if self[:'connection.port']
        self[:'connection.port']
      elsif self[:'connection.secure']
        443
      else
        80
      end
    end

    def connection_protocol
      if self[:'connection.secure']
        'https'
      else
        'http'
      end
    end

    def max_queue_size
      self[:max_queue_size]
    end

    def params_filters
      Array(self[:'request.filter_keys'])
    end

    def excluded_request_keys
      [].tap do |keys|
        keys << :session  if self[:'request.disable_session']
        keys << :params   if self[:'request.disable_params']
        keys << :cgi_data if self[:'request.disable_environment']
        keys << :url      if self[:'request.disable_url']
      end
    end

    def log_level(key = :'logging.level')
      case self[key].to_s
      when /\A(0|debug)\z/i then Logger::DEBUG
      when /\A(1|info)\z/i  then Logger::INFO
      when /\A(2|warn)\z/i  then Logger::WARN
      when /\A(3|error)\z/i then Logger::ERROR
      else
        Logger::INFO
      end
    end

    def load_plugin?(name)
      return false if includes_token?(self[:'skipped_plugins'], name)
      return true unless self[:plugins].kind_of?(Array)
      includes_token?(self[:plugins], name)
    end

    def root_regexp
      return @root_regexp if @root_regexp
      return nil if @no_root

      root = get(:root).to_s
      @no_root = true and return nil unless root =~ NOT_BLANK

      @root_regexp = Regexp.new("^#{ Regexp.escape(root) }")
    end

    def detected_framework
      if self[:framework] =~ NOT_BLANK
        self[:framework].to_sym
      elsif defined?(::Rails::VERSION) && ::Rails::VERSION::STRING > '3.0'
        :rails
      elsif defined?(::Sinatra::VERSION)
        :sinatra
      elsif defined?(::Rack.release)
        :rack
      else
        :ruby
      end
    end

    def framework_name
      case detected_framework
      when :rails then "Rails #{::Rails::VERSION::STRING}"
      when :sinatra then "Sinatra #{::Sinatra::VERSION}"
      when :rack then "Rack #{::Rack.release}"
      else
        "Ruby #{RUBY_VERSION}"
      end
    end

    private

    def detect_revision!
      return if self[:revision]
      set(:revision, Util::Revision.detect(self[:root]))
    end

    def log_path
      return if log_stdout?
      return if !self[:'logging.path']
      locate_absolute_path(self[:'logging.path'], self[:root])
    end

    def config_path
      config_paths.first
    end

    def config_paths
      Array(ENV['HONEYBADGER_CONFIG_PATH'] || get(:'config.path')).map do |c|
        locate_absolute_path(c, self[:root])
      end
    end

    def default_backend
      return Backend::Server.new(self) if public?
      Backend::Null.new(self)
    end

    def init_backend!
      if self[:backend].is_a?(String) || self[:backend].is_a?(Symbol)
        @backend = Backend.for(self[:backend].to_sym).new(self)
        return
      end

      if ruby[:backend].respond_to?(:notify)
        @backend = ruby[:backend]
        return
      end

      if ruby[:backend]
        logger.warn(sprintf('Unknown backend: %p; default will be used. Backend must respond to #notify', self[:backend]))
      end

      @backend = default_backend
    end

    def build_stdout_logger
      logger = Logger.new($stdout)
      logger.formatter = lambda do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
      logger.level = log_level
      Logging::FormattedLogger.new(logger)
    end

    def build_file_logger(path)
      Logger.new(path).tap do |logger|
        logger.level = log_level
        logger.formatter = Logger::Formatter.new
      end
    end

    def log_stdout?
      self[:'logging.path'] && self[:'logging.path'].to_s.downcase == 'stdout'
    end

    def build_logger
      return ruby[:logger] if ruby[:logger]

      return build_stdout_logger if log_stdout?

      if path = log_path
        FileUtils.mkdir_p(path.dirname) unless path.dirname.writable?
        return build_file_logger(path)
      end

      return framework[:logger] if framework[:logger]

      Logger.new(nil)
    end

    def init_logging!
      @logger = Logging::ConfigLogger.new(self, build_logger)
    end

    # Takes an Array and a value and returns true if the value exists in the
    # array in String or Symbol form, otherwise false.
    def includes_token?(obj, value)
      return false unless obj.kind_of?(Array)
      obj.map(&:to_sym).include?(value.to_sym)
    end

    def locate_absolute_path(path, root)
      path = Pathname.new(path.to_s)
      if path.absolute?
        path
      else
        Pathname.new(root.to_s).join(path.to_s)
      end
    end

    def load_config_from_disk
      if (path = config_paths.find(&:exist?)) && path.file?
        Yaml.new(path, self[:env]).tap do |yml|
          yield(yml) if block_given?
        end
      end
    end

    def undotify_keys(hash)
      {}.tap do |new_hash|
        hash.each_pair do |k,v|
          if k.to_s =~ DOTTED_KEY
            new_hash[$1] ||= {}
            new_hash[$1] = undotify_keys(new_hash[$1].merge({$2 => v}))
          else
            new_hash[k.to_s] = v
          end
        end
      end
    end
  end
end
