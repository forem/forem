require 'forwardable'

require 'honeybadger/version'
require 'honeybadger/config'
require 'honeybadger/context_manager'
require 'honeybadger/notice'
require 'honeybadger/plugin'
require 'honeybadger/logging'
require 'honeybadger/worker'
require 'honeybadger/breadcrumbs'

module Honeybadger
  # The Honeybadger agent contains all the methods for interacting with the
  # Honeybadger service. It can be used to send notifications to multiple
  # projects in large apps. The global agent instance ({Agent.instance}) should
  # always be accessed through the {Honeybadger} singleton.
  #
  # === Context
  #
  # Context is global by default, meaning agents created via
  # +Honeybadger::Agent.new+ will share context (added via
  # +Honeybadger.context+ or {Honeybadger::Agent#context}) with other agents.
  # This also includes the Rack environment when using the
  # {Honeybadger::Rack::ErrorNotifier} middleware. To localize context for a
  # custom agent, use the +local_context: true+ option when initializing.
  #
  # @example
  #
  #   # Standard usage:
  #   OtherBadger = Honeybadger::Agent.new
  #
  #   # With local context:
  #   OtherBadger = Honeybadger::Agent.new(local_context: true)
  #
  #   OtherBadger.configure do |config|
  #     config.api_key = 'project api key'
  #   end
  #
  #   begin
  #     # Risky operation
  #   rescue => e
  #     OtherBadger.notify(e)
  #   end
  class Agent
    extend Forwardable

    include Logging::Helper

    # @api private
    def self.instance
      @instance
    end

    # @api private
    def self.instance=(instance)
      @instance = instance
    end

    def initialize(opts = {})
      if opts.kind_of?(Config)
        @config = opts
        opts = {}
      end

      @context = opts.delete(:context)
      local_context = opts.delete(:local_context)

      @config ||= Config.new(opts)

      if local_context
        @context ||= ContextManager.new
        @breadcrumbs = Breadcrumbs::Collector.new(config)
      else
        @breadcrumbs = nil
      end

      init_worker
    end

    # Sends an exception to Honeybadger. Does not report ignored exceptions by
    # default.
    #
    # @example
    #   # With an exception:
    #   begin
    #     fail 'oops'
    #   rescue => exception
    #     Honeybadger.notify(exception, context: {
    #       my_data: 'value'
    #     }) # => '-1dfb92ae-9b01-42e9-9c13-31205b70744a'
    #   end
    #
    #   # Custom notification:
    #   Honeybadger.notify('Something went wrong.', {
    #     error_class: 'MyClass',
    #     context: {my_data: 'value'}
    #   }) # => '06220c5a-b471-41e5-baeb-de247da45a56'
    #
    # @param [Exception, Hash, Object] exception_or_opts An Exception object,
    #   or a Hash of options which is used to build the notice. All other types
    #   of objects will be converted to a String and used as the :error_message.
    # @param [Hash] opts The options Hash when the first argument is an Exception.
    #
    # @option opts [String]    :error_message The error message.
    # @option opts [String]    :error_class ('Notice') The class name of the error.
    # @option opts [Array]     :backtrace The backtrace of the error (optional).
    # @option opts [String]    :fingerprint The grouping fingerprint of the exception (optional).
    # @option opts [Boolean]   :force (false) Always report the exception when true, even when ignored (optional).
    # @option opts [Boolean]   :sync (false) Send data synchronously (skips the worker) (optional).
    # @option opts [String]    :tags The comma-separated list of tags (optional).
    # @option opts [Hash]      :context The context to associate with the exception (optional).
    # @option opts [String]    :controller The controller name (such as a Rails controller) (optional).
    # @option opts [String]    :action The action name (such as a Rails controller action) (optional).
    # @option opts [Hash]      :parameters The HTTP request paramaters (optional).
    # @option opts [Hash]      :session The HTTP request session (optional).
    # @option opts [String]    :url The HTTP request URL (optional).
    # @option opts [Exception] :cause The cause for this error (optional).
    #
    # @return [String] UUID reference to the notice within Honeybadger.
    # @return [false] when ignored.
    def notify(exception_or_opts, opts = {})
      opts = opts.dup

      if exception_or_opts.is_a?(Exception)
        opts[:exception] = exception_or_opts
      elsif exception_or_opts.respond_to?(:to_hash)
        opts.merge!(exception_or_opts.to_hash)
      else
        opts[:error_message] = exception_or_opts.to_s
      end

      validate_notify_opts!(opts)

      add_breadcrumb(
        "Honeybadger Notice",
        metadata: opts,
        category: "notice"
      ) if config[:'breadcrumbs.enabled']

      opts[:rack_env] ||= context_manager.get_rack_env
      opts[:global_context] ||= context_manager.get_context
      opts[:breadcrumbs] ||= breadcrumbs.dup

      notice = Notice.new(config, opts)

      config.before_notify_hooks.each do |hook|
        break if notice.halted?
        with_error_handling { hook.call(notice) }
      end

      unless notice.api_key =~ NOT_BLANK
        error { sprintf('Unable to send error report: API key is missing. id=%s', notice.id) }
        return false
      end

      if !opts[:force] && notice.ignore?
        debug { sprintf('ignore notice feature=notices id=%s', notice.id) }
        return false
      end

      if notice.halted?
        debug { 'halted notice feature=notices' }
        return false
      end

      info { sprintf('Reporting error id=%s', notice.id) }

      if opts[:sync] || config[:sync]
        send_now(notice)
      else
        push(notice)
      end

      notice.id
    end

    # Perform a synchronous check_in.
    #
    # @example
    #   Honeybadger.check_in('1MqIo1')
    #
    # @param [String] id The unique check in id (e.g. '1MqIo1') or the check in url.
    #
    # @return [Boolean] true if the check in was successful and false
    #   otherwise.
    def check_in(id)
      # this is to allow check ins even if a url is passed
      check_in_id = id.to_s.strip.gsub(/\/$/, '').split('/').last
      response = backend.check_in(check_in_id)
      response.success?
    end

    # Track a new deployment
    #
    # @example
    #   Honeybadger.track_deployment(revision: 'be2ceb6')
    #
    # @param [String] :environment The environment name. Defaults to the current configured environment.
    # @param [String] :revision The VCS revision being deployed. Defaults to the currently configured revision.
    # @param [String] :local_username The name of the user who performed the deploy.
    # @param [String] :repository The base URL of the VCS repository. It should be HTTPS-style.
    #
    # @return [Boolean] true if the deployment was successfully tracked and false
    #   otherwise.
    def track_deployment(environment: nil, revision: nil, local_username: nil, repository: nil)
      opts = {
        environment: environment || config[:env],
        revision: revision || config[:revision],
        local_username: local_username,
        repository: repository
      }
      response = backend.track_deployment(opts)
      response.success?
    end

    # Save global context for the current request.
    #
    # @example
    #   Honeybadger.context({my_data: 'my value'})
    #
    #   # Inside a Rails controller:
    #   before_action do
    #     Honeybadger.context({user_id: current_user.id})
    #   end
    #
    #   # Explicit conversion
    #   class User < ActiveRecord::Base
    #     def to_honeybadger_context
    #       { user_id: id, user_email: email }
    #     end
    #   end
    #
    #   user = User.first
    #   Honeybadger.context(user)
    #
    #   # Clearing global context:
    #   Honeybadger.context.clear!
    #
    # @param [Hash] context A Hash of data which will be sent to Honeybadger
    #   when an error occurs. If the object responds to +#to_honeybadger_context+,
    #   the return value of that method will be used (explicit conversion). Can
    #   include any key/value, but a few keys have a special meaning in
    #   Honeybadger.
    #
    # @option context [String] :user_id The user ID used by Honeybadger
    #   to aggregate user data across occurrences on the error page (optional).
    # @option context [String] :user_email The user email address (optional).
    # @option context [String] :tags The comma-separated list of tags.
    #   When present, tags will be applied to errors with this context
    #   (optional).
    #
    # @return [self] so that method calls can be chained.
    def context(context = nil)
      context_manager.set_context(context) unless context.nil?
      self
    end

    # Clear all transaction scoped data.
    def clear!
      context_manager.clear!
      breadcrumbs.clear!
    end

    # Get global context for the current request.
    #
    # @example
    #   Honeybadger.context({my_data: 'my value'})
    #   Honeybadger.get_context # => {my_data: 'my value'}
    #
    # @return [Hash, nil]
    def get_context
      context_manager.get_context
    end

    # @api private
    # Direct access to the Breadcrumbs::Collector instance
    def breadcrumbs
      return @breadcrumbs if @breadcrumbs

      Thread.current[:__hb_breadcrumbs] ||= Breadcrumbs::Collector.new(config)
    end

    # Appends a breadcrumb to the trace. Use this when you want to add some
    # custom data to your breadcrumb trace in effort to help debugging. If a
    # notice is reported to Honeybadger, all breadcrumbs within the execution
    # path will be appended to the notice. You will be able to view the
    # breadcrumb trace in the Honeybadger interface to see what events led up
    # to the notice.
    #
    # @example
    #   Honeybadger.add_breadcrumb("Email Sent", metadata: { user: user.id, message: message })
    #
    # @param message [String] The message you want to send with the breadcrumb
    # @param params [Hash] extra options for breadcrumb building
    # @option params [Hash] :metadata Any metadata that you want to pass along
    #   with the breadcrumb. We only accept a hash with simple primatives as
    #   values (Strings, Numbers, Booleans & Symbols) (optional)
    # @option params [String] :category You can provide a custom category. This
    #   affects how the breadcrumb is displayed, so we recommend that you pick a
    #   known category. (optional)
    #
    # @return self
    def add_breadcrumb(message, metadata: {}, category: "custom")
      params = Util::Sanitizer.new(max_depth: 2).sanitize({
        category: category,
        message: message,
        metadata: metadata
      })

      breadcrumbs.add!(Breadcrumbs::Breadcrumb.new(**params))

      self
    end

    # Flushes all data from workers before returning. This is most useful in
    # tests when using the test backend, where normally the asynchronous nature
    # of this library could create race conditions.
    #
    # @example
    #   # Without a block:
    #   it "sends a notification to Honeybadger" do
    #     expect {
    #       Honeybadger.notify(StandardError.new('test backend'))
    #       Honeybadger.flush
    #     }.to change(Honeybadger::Backend::Test.notifications[:notices], :size).by(0)
    #   end
    #
    #   # With a block:
    #   it "sends a notification to Honeybadger" do
    #     expect {
    #       Honeybadger.flush do
    #         49.times do
    #           Honeybadger.notify(StandardError.new('test backend'))
    #         end
    #       end
    #     }.to change(Honeybadger::Backend::Test.notifications[:notices], :size).by(49)
    #   end
    #
    # @yield An optional block to execute (exceptions will propagate after
    #   data is flushed).
    #
    # @return [Object, Boolean] value of block if block is given, otherwise true
    #   on success or false if Honeybadger isn't running.
    def flush
      return true unless block_given?
      yield
    ensure
      worker.flush
    end

    # Stops the Honeybadger service.
    #
    # @example
    #   Honeybadger.stop # => nil
    def stop(force = false)
      worker.shutdown(force)
      true
    end

    # @api private
    attr_reader :config

    # Configure the Honeybadger agent via Ruby.
    #
    # @example
    #   Honeybadger.configure do |config|
    #     config.api_key = 'project api key'
    #     config.exceptions.ignore += [CustomError]
    #   end
    #
    # @!method configure
    # @yield [Config::Ruby] configuration object.
    def_delegator :config, :configure

    # DEPRECATED: Callback to ignore exceptions.
    #
    # See public API documentation for {Honeybadger::Notice} for available attributes.
    #
    # @example
    #   # Ignoring based on error message:
    #   Honeybadger.exception_filter do |notice|
    #     notice.error_message =~ /sensitive data/
    #   end
    #
    #   # Ignore an entire class of exceptions:
    #   Honeybadger.exception_filter do |notice|
    #     notice.exception.class < MyError
    #   end
    #
    # @!method exception_filter
    # @yieldreturn [Boolean] true (to ignore) or false (to send).
    def_delegator :config, :exception_filter

    # DEPRECATED: Callback to add a custom grouping strategy for exceptions. The return
    # value is hashed and sent to Honeybadger. Errors with the same fingerprint
    # will be grouped.
    #
    # See public API documentation for {Honeybadger::Notice} for available attributes.
    #
    # @example
    #   Honeybadger.exception_fingerprint do |notice|
    #     [notice.error_class, notice.component, notice.backtrace.to_s].join(':')
    #   end
    #
    # @!method exception_fingerprint
    # @yieldreturn [#to_s] The fingerprint of the error.
    def_delegator :config, :exception_fingerprint

    # DEPRECATED: Callback to filter backtrace lines. One use for this is to make
    # additional [PROJECT_ROOT] or [GEM_ROOT] substitutions, which are used by
    # Honeybadger when grouping errors and displaying application traces.
    #
    # @example
    #   Honeybadger.backtrace_filter do |line|
    #     line.gsub(/^\/my\/unknown\/bundle\/path/, "[GEM_ROOT]")
    #   end
    #
    # @!method backtrace_filter
    # @yieldparam  [String] line The backtrace line to modify.
    # @yieldreturn [String] The new (modified) backtrace line.
    def_delegator :config, :backtrace_filter

    # @api private
    def with_rack_env(rack_env, &block)
      context_manager.set_rack_env(rack_env)
      yield
    ensure
      context_manager.set_rack_env(nil)
    end

    # @api private
    attr_reader :worker

    # @api private
    # @!method init!(...)
    # @see Config#init!
    def_delegators :config, :init!

    # @api private
    # @!method backend
    # @see Config#backend
    def_delegators :config, :backend

    private

    def validate_notify_opts!(opts)
      return if opts.has_key?(:exception)
      return if opts.has_key?(:error_message)
      msg = sprintf('`Honeybadger.notify` was called with invalid arguments. You must pass either an Exception or options Hash containing the `:error_message` key. location=%s', caller[caller.size-1])
      raise ArgumentError.new(msg) if config.dev?
      warn(msg)
    end

    def context_manager
      return @context if @context
      ContextManager.current
    end

    def push(object)
      worker.push(object)
      true
    end

    def send_now(object)
      worker.send_now(object)
      true
    end

    def init_worker
      @worker = Worker.new(config)
    end

    def with_error_handling
      yield
    rescue => ex
      error { "Rescued an error in a before notify hook: #{ex.message}" }
    end

    @instance = new(Config.new)
  end
end
