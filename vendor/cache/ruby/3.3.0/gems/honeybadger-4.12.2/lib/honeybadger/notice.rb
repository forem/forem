require 'json'
require 'securerandom'
require 'forwardable'

require 'honeybadger/version'
require 'honeybadger/backtrace'
require 'honeybadger/conversions'
require 'honeybadger/util/stats'
require 'honeybadger/util/sanitizer'
require 'honeybadger/util/request_hash'
require 'honeybadger/util/request_payload'

module Honeybadger
  # @api private
  NOTIFIER = {
    name: 'honeybadger-ruby'.freeze,
    url: 'https://github.com/honeybadger-io/honeybadger-ruby'.freeze,
    version: VERSION,
    language: 'ruby'.freeze
  }.freeze

  # @api private
  # Substitution for gem root in backtrace lines.
  GEM_ROOT = '[GEM_ROOT]'.freeze

  # @api private
  # Substitution for project root in backtrace lines.
  PROJECT_ROOT = '[PROJECT_ROOT]'.freeze

  # @api private
  # Empty String (used for equality comparisons and assignment).
  STRING_EMPTY = ''.freeze

  # @api private
  # A Regexp which matches non-blank characters.
  NOT_BLANK = /\S/.freeze

  # @api private
  # Matches lines beginning with ./
  RELATIVE_ROOT = Regexp.new('^\.\/').freeze

  # @api private
  MAX_EXCEPTION_CAUSES = 5

  # @api private
  # Binding#source_location was added in Ruby 2.6.
  BINDING_HAS_SOURCE_LOCATION = Binding.method_defined?(:source_location)

  class Notice
    extend Forwardable

    include Conversions

    # @api private
    # The String character used to split tag strings.
    TAG_SEPERATOR = /,|\s/.freeze

    # @api private
    # The Regexp used to strip invalid characters from individual tags.
    TAG_SANITIZER = /\s/.freeze

    # @api private
    class Cause
      attr_accessor :error_class, :error_message, :backtrace

      def initialize(cause)
        self.error_class = cause.class.name
        self.error_message = cause.message
        self.backtrace = cause.backtrace
      end
    end

    # The unique ID of this notice which can be used to reference the error in
    # Honeybadger.
    attr_reader :id

    # The exception that caused this notice, if any.
    attr_reader :exception

    # The exception cause if available.
    attr_reader :cause
    def cause=(cause)
      @cause = cause
      @causes = unwrap_causes(cause)
    end

    # @return [Cause] A list of exception causes (see {Cause})
    attr_reader :causes

    # The backtrace from the given exception or hash.
    attr_accessor :backtrace

    # Custom fingerprint for error, used to group similar errors together.
    attr_accessor :fingerprint

    # Tags which will be applied to error.
    attr_reader :tags
    def tags=(tags)
      @tags = construct_tags(tags)
    end

    # The name of the class of error (example: RuntimeError).
    attr_accessor :error_class

    # The message from the exception, or a general description of the error.
    attr_accessor :error_message

    # The context Hash.
    attr_accessor :context

    # CGI variables such as HTTP_METHOD.
    attr_accessor :cgi_data

    # A hash of parameters from the query string or post body.
    attr_accessor :params
    alias_method :parameters, :params

    # The component (if any) which was used in this request (usually the controller).
    attr_accessor :component
    alias_method :controller, :component
    alias_method :controller=, :component=

    # The action (if any) that was called in this request.
    attr_accessor :action

    # A hash of session data from the request.
    attr_accessor :session

    # The URL at which the error occurred (if any).
    attr_accessor :url

    # Local variables are extracted from first frame of backtrace.
    attr_accessor :local_variables

    # The API key used to deliver this notice.
    attr_accessor :api_key

    # Deprecated: Excerpt from source file.
    attr_reader :source

    # @return [Breadcrumbs::Collector] The collection of captured breadcrumbs
    attr_accessor :breadcrumbs

    # Custom details data
    attr_accessor :details

    # @api private
    # Cache project path substitutions for backtrace lines.
    PROJECT_ROOT_CACHE = {}

    # @api private
    # Cache gem path substitutions for backtrace lines.
    GEM_ROOT_CACHE = {}

    # @api private
    # A list of backtrace filters to run all the time.
    BACKTRACE_FILTERS = [
      lambda { |line|
        return line unless defined?(Gem)
        GEM_ROOT_CACHE[line] ||= Gem.path.reduce(line) do |line, path|
          line.sub(path, GEM_ROOT)
        end
      },
      lambda { |line, config|
        return line unless config
        c = (PROJECT_ROOT_CACHE[config[:root]] ||= {})
        return c[line] if c.has_key?(line)
        c[line] ||= if config.root_regexp
                      line.sub(config.root_regexp, PROJECT_ROOT)
                    else
                      line
                    end
      },
      lambda { |line| line.sub(RELATIVE_ROOT, STRING_EMPTY) },
      lambda { |line| line if line !~ %r{lib/honeybadger} }
    ].freeze

    # @api private
    def initialize(config, opts = {})
      @now   = Time.now.utc
      @pid   = Process.pid
      @id    = SecureRandom.uuid
      @stats = Util::Stats.all

      @opts = opts
      @config = config

      @rack_env = opts.fetch(:rack_env, nil)
      @request_sanitizer = Util::Sanitizer.new(filters: params_filters)

      @exception = unwrap_exception(opts[:exception])

      self.error_class = exception_attribute(:error_class, 'Notice') {|exception| exception.class.name }
      self.error_message = exception_attribute(:error_message, 'No message provided') do |exception|
        "#{exception.class.name}: #{exception.message}"
      end
      self.backtrace = exception_attribute(:backtrace, caller)
      self.cause = opts.key?(:cause) ? opts[:cause] : (exception_cause(@exception) || $!)

      self.context = construct_context_hash(opts, exception)
      self.local_variables = local_variables_from_exception(exception, config)
      self.api_key = opts[:api_key] || config[:api_key]
      self.tags = construct_tags(opts[:tags]) | construct_tags(context[:tags])

      self.url       = opts[:url]        || request_hash[:url]      || nil
      self.action    = opts[:action]     || request_hash[:action]   || nil
      self.component = opts[:controller] || opts[:component]        || request_hash[:component] || nil
      self.params    = opts[:parameters] || opts[:params]           || request_hash[:params] || {}
      self.session   = opts[:session]    || request_hash[:session]  || {}
      self.cgi_data  = opts[:cgi_data]   || request_hash[:cgi_data] || {}
      self.details   = opts[:details]    || {}

      self.session = opts[:session][:data] if opts[:session] && opts[:session][:data]

      self.breadcrumbs = opts[:breadcrumbs] || Breadcrumbs::Collector.new(config)

      # Fingerprint must be calculated last since callback operates on `self`.
      self.fingerprint = fingerprint_from_opts(opts)
    end

    # @api private
    # Template used to create JSON payload.
    #
    # @return [Hash] JSON representation of notice.
    def as_json(*args)
      request = construct_request_hash
      request[:context] = s(context)
      request[:local_variables] = local_variables if local_variables

      {
        api_key: s(api_key),
        notifier: NOTIFIER,
        breadcrumbs: sanitized_breadcrumbs,
        error: {
          token: id,
          class: s(error_class),
          message: s(error_message),
          backtrace: s(parse_backtrace(backtrace)),
          fingerprint: fingerprint_hash,
          tags: s(tags),
          causes: s(prepare_causes(causes))
        },
        details: s(details),
        request: request,
        server: {
          project_root: s(config[:root]),
          revision: s(config[:revision]),
          environment_name: s(config[:env]),
          hostname: s(config[:hostname]),
          stats: stats,
          time: now,
          pid: pid
        }
      }
    end

    # Converts the notice to JSON.
    #
    # @return [Hash] The JSON representation of the notice.
    def to_json(*a)
      ::JSON.generate(as_json(*a))
    end

    # @api private
    # Determines if this notice should be ignored.
    def ignore?
      ignore_by_origin? || ignore_by_class? || ignore_by_callbacks?
    end

    # Halts the notice and the before_notify callback chain.
    #
    # Returns nothing.
    def halt!
      @halted ||= true
    end

    # @api private
    # Determines if this notice will be discarded.
    def halted?
      !!@halted
    end

    private

    attr_reader :config, :opts, :stats, :now, :pid, :request_sanitizer,
      :rack_env

    def ignore_by_origin?
      return false if opts[:origin] != :rake
      return false if config[:'exceptions.rescue_rake']
      true
    end

    def ignore_by_callbacks?
      config.exception_filter &&
        config.exception_filter.call(self)
    end

    # Gets a property named "attribute" of an exception, either from
    # the #args hash or actual exception (in order of precidence).
    #
    # attribute - A Symbol existing as a key in #args and/or attribute on
    #             Exception.
    # default   - Default value if no other value is found (optional).
    # block     - An optional block which receives an Exception and returns the
    #             desired value.
    #
    # Returns attribute value from args or exception, otherwise default.
    def exception_attribute(attribute, default = nil, &block)
      opts[attribute] || (exception && from_exception(attribute, &block)) || default
    end

    # Gets a property named +attribute+ from an exception.
    #
    # If a block is given, it will be used when getting the property from an
    # exception. The block should accept and exception and return the value for
    # the property.
    #
    # If no block is given, a method with the same name as +attribute+ will be
    # invoked for the value.
    def from_exception(attribute)
      return unless exception

      if block_given?
        yield(exception)
      else
        exception.send(attribute)
      end
    end

    # Determines if error class should be ignored.
    #
    # ignored_class_name - The name of the ignored class. May be a
    # string or regexp (optional).
    #
    # Returns true or false.
    def ignore_by_class?(ignored_class = nil)
      @ignore_by_class ||= Proc.new do |ignored_class|
        case error_class
        when (ignored_class.respond_to?(:name) ? ignored_class.name : ignored_class)
          true
        else
          exception && ignored_class.is_a?(Class) && exception.class < ignored_class
        end
      end

      ignored_class ? @ignore_by_class.call(ignored_class) : config.ignored_classes.any?(&@ignore_by_class)
    end

    def construct_backtrace_filters(opts)
      [
        config.backtrace_filter
      ].compact | BACKTRACE_FILTERS
    end

    def request_hash
      @request_hash ||= Util::RequestHash.from_env(rack_env)
    end

    # Construct the request data.
    #
    # Returns Hash request data.
    def construct_request_hash
      request = {
        url: url,
        component: component,
        action: action,
        params: params,
        session: session,
        cgi_data: cgi_data,
        sanitizer: request_sanitizer
      }
      request.delete_if {|k,v| config.excluded_request_keys.include?(k) }
      Util::RequestPayload.build(request)
    end

    # Get optional context from exception.
    #
    # Returns the Hash context.
    def exception_context(exception)
      # This extra check exists because the exception itself is not expected to
      # convert to a hash.
      object = exception if exception.respond_to?(:to_honeybadger_context)
      object ||= {}.freeze

      Context(object)
    end

    # Sanitize metadata to keep it at a single level and remove any filtered
    # parameters
    def sanitized_breadcrumbs
      sanitizer = Util::Sanitizer.new(max_depth: 1, filters: params_filters)
      breadcrumbs.each do |breadcrumb|
        breadcrumb.metadata = sanitizer.sanitize(breadcrumb.metadata)
      end

      breadcrumbs.to_h
    end

    def construct_context_hash(opts, exception)
      context = {}
      context.merge!(Context(opts[:global_context]))
      context.merge!(exception_context(exception))
      context.merge!(Context(opts[:context]))
      context
    end

    def fingerprint_from_opts(opts)
      callback = opts[:fingerprint]
      callback ||= config.exception_fingerprint

      if callback.respond_to?(:call)
        callback.call(self)
      else
        callback
      end
    end

    def fingerprint_hash
      return unless fingerprint
      Digest::SHA1.hexdigest(fingerprint.to_s)
    end

    def construct_tags(tags)
      ret = []
      Array(tags).flatten.each do |val|
        val.to_s.split(TAG_SEPERATOR).each do |tag|
          tag.gsub!(TAG_SANITIZER, STRING_EMPTY)
          ret << tag if tag =~ NOT_BLANK
        end
      end

      ret
    end

    def s(data)
      Util::Sanitizer.sanitize(data)
    end

    # Fetch local variables from first frame of backtrace.
    #
    # exception - The Exception containing the bindings stack.
    #
    # Returns a Hash of local variables.
    def local_variables_from_exception(exception, config)
      return nil unless send_local_variables?(config)
      return {} unless Exception === exception
      return {} unless exception.respond_to?(:__honeybadger_bindings_stack)
      return {} if exception.__honeybadger_bindings_stack.empty?

      if config[:root]
        binding = exception.__honeybadger_bindings_stack.find { |b|
          if BINDING_HAS_SOURCE_LOCATION
            b.source_location[0]
          else
            b.eval('__FILE__')
          end =~ /^#{Regexp.escape(config[:root].to_s)}/
        }
      end

      binding ||= exception.__honeybadger_bindings_stack[0]

      vars = binding.eval('local_variables')
      results =
        vars.inject([]) { |acc, arg|
          begin
            result = binding.eval(arg.to_s)
            acc << [arg, result]
          rescue NameError
            # Do Nothing
          end

          acc
        }

      result_hash = Hash[results]
      request_sanitizer.sanitize(result_hash)
    end

    # Should local variables be sent?
    #
    # Returns true to send local_variables.
    def send_local_variables?(config)
      config[:'exceptions.local_variables']
    end

    # Parse Backtrace from exception backtrace.
    #
    # backtrace - The Array backtrace from exception.
    #
    # Returns the Backtrace.
    def parse_backtrace(backtrace)
      Backtrace.parse(
        backtrace,
        filters: construct_backtrace_filters(opts),
        config: config,
        source_radius: config[:'exceptions.source_radius']
      ).to_a
    end

    # Unwrap the exception so that original exception is ignored or
    # reported.
    #
    # exception - The exception which was rescued.
    #
    # Returns the Exception to report.
    def unwrap_exception(exception)
      return exception unless config[:'exceptions.unwrap']
      exception_cause(exception) || exception
    end

    # Fetch cause from exception.
    #
    # exception - Exception to fetch cause from.
    #
    # Returns the Exception cause.
    def exception_cause(exception)
      e = exception
      if e.respond_to?(:cause) && e.cause && e.cause.is_a?(Exception)
        e.cause
      elsif e.respond_to?(:original_exception) && e.original_exception && e.original_exception.is_a?(Exception)
        e.original_exception
      elsif e.respond_to?(:continued_exception) && e.continued_exception && e.continued_exception.is_a?(Exception)
        e.continued_exception
      end
    end

    # Create a list of causes.
    #
    # cause - The first cause to unwrap.
    #
    # Returns the Array of Cause instances.
    def unwrap_causes(cause)
      causes, c, i = [], cause, 0

      while c && i < MAX_EXCEPTION_CAUSES
        causes << Cause.new(c)
        i += 1
        c = exception_cause(c)
      end

      causes
    end

    # Convert list of causes into payload format.
    #
    # causes - Array of Cause instances.
    #
    # Returns the Array of causes in Hash payload format.
    def prepare_causes(causes)
      causes.map {|c|
        {
          class: c.error_class,
          message: c.error_message,
          backtrace: parse_backtrace(c.backtrace)
        }
      }
    end

    def params_filters
      config.params_filters + rails_params_filters
    end

    def rails_params_filters
      rack_env && Array(rack_env['action_dispatch.parameter_filter']) or []
    end
  end
end
