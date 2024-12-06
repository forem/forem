require 'forwardable'

module Honeybadger
  # +Honeybadger::Plugin+ defines the API for registering plugins with
  # Honeybadger. Each plugin has requirements which must be satisfied before
  # executing the plugin's execution block(s). This allows us to detect
  # optional dependencies and load the plugin for each dependency only if it's
  # present in the application.
  #
  # See the plugins/ directory for examples of official plugins. If you're
  # interested in developing a plugin for Honeybadger, see the Integration
  # Guide: https://docs.honeybadger.io/ruby/gem-reference/integration.html
  #
  # @example
  #
  #   require 'honeybadger/plugin'
  #   require 'honeybadger/ruby'
  #
  #   module Honeybadger
  #     module Plugins
  #       # Register your plugin with an optional name. If the name (such as
  #       # "my_framework") is not provided, Honeybadger will try to infer the name
  #       # from the current file.
  #       Plugin.register 'my_framework' do
  #         requirement do
  #           # Check to see if the thing you're integrating with is loaded. Return true
  #           # if it is, or false if it isn't. An exception in this block is equivalent
  #           # to returning false. Multiple requirement blocks are supported.
  #           defined?(MyFramework)
  #         end
  #
  #         execution do
  #           # Write your integration. This code will be executed only if all requirement
  #           # blocks return true. An exception in this block will disable the plugin.
  #           # Multiple execution blocks are supported.
  #           MyFramework.on_exception do |exception|
  #             Honeybadger.notify(exception)
  #           end
  #         end
  #       end
  #     end
  #   end
  class Plugin
    # @api private
    CALLER_FILE = Regexp.new('\A(?:\w:)?([^:]+)(?=(:\d+))').freeze

    class << self
      # @api private
      @@instances = {}

      # @api private
      def instances
        @@instances
      end

      # Register a new plugin with Honeybadger. See {#requirement} and {#execution}.
      #
      # @example
      #
      #   Honeybadger::Plugin.register 'my_framework' do
      #     requirement { }
      #     execution { }
      #   end
      #
      # @param [String, Symbol] name The optional name of the plugin. Should use
      #   +snake_case+. The name is inferred from the current file name if omitted.
      #
      # @return nil
      def register(name = nil, &block)
        name ||= name_from_caller(caller) or
          raise(ArgumentError, 'Plugin name is required, but was nil.')
        instances[key = name.to_sym] and fail("Already registered: #{name}")
        instances[key] = new(name).tap { |d| d.instance_eval(&block) }
      end

      # @api private
      def load!(config)
        instances.each_pair do |name, plugin|
          if config.load_plugin?(name)
            plugin.load!(config)
          else
            config.logger.debug(sprintf('skip plugin name=%s reason=disabled', name))
          end
        end
      end

      # @api private
      def name_from_caller(caller)
        caller && caller[0].match(CALLER_FILE) or
          fail("Unable to determine name from caller: #{caller.inspect}")
        File.basename($1)[/[^\.]+/]
      end
    end

    # @api private
    class Execution
      extend Forwardable

      def initialize(config, &block)
        @config = config
        @block = block
      end

      def call
        instance_eval(&block)
      end

      private

      attr_reader :config, :block
      def_delegator :@config, :logger
    end

    # @api private
    def initialize(name)
      @name         = name
      @loaded       = false
      @requirements = []
      @executions   = []
    end

    # Define a requirement. All requirement blocks must return +true+ for the
    # plugin to be executed.
    #
    # @example
    #
    #   Honeybadger::Plugin.register 'my_framework' do
    #     requirement { defined?(MyFramework) }
    #
    #     # Honeybadger's configuration object is available inside
    #     # requirement blocks. It should generally not be used outside of
    #     # internal plugins. See +Config+.
    #     requirement { config[:'my_framework.enabled'] }
    #
    #     execution { }
    #   end
    #
    # @return nil
    def requirement(&block)
      @requirements << block
    end

    # Define an execution block. Execution blocks will be executed if all
    # requirement blocks return +true+.
    #
    # @example
    #
    #   Honeybadger::Plugin.register 'my_framework' do
    #     requirement { defined?(MyFramework) }
    #
    #     execution do
    #       MyFramework.on_exception {|err| Honeybadger.notify(err) }
    #     end
    #
    #     execution do
    #       # Honeybadger's configuration object is available inside
    #       # execution blocks. It should generally not be used outside of
    #       # internal plugins. See +Config+.
    #       MyFramework.use_middleware(MyMiddleware) if config[:'my_framework.use_middleware']
    #     end
    #   end
    #
    # @return nil
    def execution(&block)
      @executions << block
    end

    # @api private
    def ok?(config)
      @requirements.all? {|r| Execution.new(config, &r).call }
    rescue => e
      config.logger.error(sprintf("plugin error name=%s class=%s message=%s\n\t%s", name, e.class, e.message.dump, Array(e.backtrace).join("\n\t")))
      false
    end

    # @api private
    def load!(config)
      if @loaded
        config.logger.debug(sprintf('skip plugin name=%s reason=loaded', name))
        return false
      elsif ok?(config)
        config.logger.debug(sprintf('load plugin name=%s', name))
        @executions.each {|e| Execution.new(config, &e).call }
        @loaded = true
      else
        config.logger.debug(sprintf('skip plugin name=%s reason=requirement', name))
      end

      @loaded
    rescue => e
      config.logger.error(sprintf("plugin error name=%s class=%s message=%s\n\t%s", name, e.class, e.message.dump, Array(e.backtrace).join("\n\t")))
      @loaded = true
      false
    end

    # @api private
    def loaded?
      @loaded
    end

    # @private
    # Used for testing only; don't normally call this. :)
    def reset!
      @loaded = false
    end

    # @api private
    attr_reader :name, :requirements, :executions
  end
end
