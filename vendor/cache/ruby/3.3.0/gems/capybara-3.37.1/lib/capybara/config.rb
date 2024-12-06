# frozen_string_literal: true

require 'forwardable'
require 'capybara/session/config'

module Capybara
  class Config
    extend Forwardable

    OPTIONS = %i[
      app reuse_server threadsafe server default_driver javascript_driver use_html5_parsing allow_gumbo
    ].freeze

    attr_accessor :app, :use_html5_parsing
    attr_reader :reuse_server, :threadsafe, :session_options # rubocop:disable Style/BisectedAttrAccessor
    attr_writer :default_driver, :javascript_driver

    SessionConfig::OPTIONS.each do |method|
      def_delegators :session_options, method, "#{method}="
    end

    def initialize
      @session_options = Capybara::SessionConfig.new
      @javascript_driver = nil
    end

    attr_writer :reuse_server # rubocop:disable Style/BisectedAttrAccessor

    def threadsafe=(bool)
      if (bool != threadsafe) && Session.instance_created?
        raise 'Threadsafe setting cannot be changed once a session is created'
      end

      @threadsafe = bool
    end

    ##
    #
    # Return the proc that Capybara will call to run the Rack application.
    # The block returned receives a rack app, port, and host/ip and should run a Rack handler
    # By default, Capybara will try to use puma.
    #
    attr_reader :server

    ##
    #
    # Set the server to use.
    #
    #     Capybara.server = :webrick
    #     Capybara.server = :puma, { Silent: true }
    #
    # @overload server=(name)
    #   @param [Symbol] name     Name of the server type to use
    # @overload server=([name, options])
    #   @param [Symbol] name Name of the server type to use
    #   @param [Hash] options Options to pass to the server block
    # @see register_server
    #
    def server=(name)
      name, options = *name if name.is_a? Array
      @server = if name.respond_to? :call
        name
      elsif options
        proc { |app, port, host| Capybara.servers[name.to_sym].call(app, port, host, **options) }
      else
        Capybara.servers[name.to_sym]
      end
    end

    ##
    #
    # @return [Symbol]    The name of the driver to use by default
    #
    def default_driver
      @default_driver || :rack_test
    end

    ##
    #
    # @return [Symbol]    The name of the driver used when JavaScript is needed
    #
    def javascript_driver
      @javascript_driver || :selenium
    end

    def deprecate(method, alternate_method, once: false)
      @deprecation_notified ||= {}
      unless once && @deprecation_notified[method]
        Capybara::Helpers.warn "DEPRECATED: ##{method} is deprecated, please use ##{alternate_method} instead: #{Capybara::Helpers.filter_backtrace(caller)}"
      end
      @deprecation_notified[method] = true
    end

    def allow_gumbo=(val)
      deprecate('allow_gumbo=', 'use_html5_parsing=')
      self.use_html5_parsing = val
    end

    def allow_gumbo
      deprecate('allow_gumbo', 'use_html5_parsing')
      use_html5_parsing
    end
  end
end
