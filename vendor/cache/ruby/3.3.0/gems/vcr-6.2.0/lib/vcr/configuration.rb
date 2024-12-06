require 'vcr/util/hooks'
require 'uri'
require 'cgi'

module VCR
  # Stores the VCR configuration.
  class Configuration
    include Hooks
    include VariableArgsBlockCaller
    include Logger::Mixin

    # Gets the directory to read cassettes from and write cassettes to.
    #
    # @return [String] the directory to read cassettes from and write cassettes to
    def cassette_library_dir
      VCR.cassette_persisters[:file_system].storage_location
    end

    # Sets the directory to read cassettes from and writes cassettes to.
    #
    # @example
    #   VCR.configure do |c|
    #     c.cassette_library_dir = 'spec/cassettes'
    #   end
    #
    # @param dir [String] the directory to read cassettes from and write cassettes to
    # @return [void]
    # @note This is only necessary if you use the `:file_system`
    #   cassette persister (the default).
    def cassette_library_dir=(dir)
      VCR.cassette_persisters[:file_system].storage_location = dir
    end

    # Default options to apply to every cassette.
    #
    # @overload default_cassette_options
    #   @return [Hash] default options to apply to every cassette
    # @overload default_cassette_options=(options)
    #   @param options [Hash] default options to apply to every cassette
    #   @return [void]
    # @example
    #   VCR.configure do |c|
    #     c.default_cassette_options = { :record => :new_episodes }
    #   end
    # @note {VCR#insert_cassette} for the list of valid options.
    attr_reader :default_cassette_options

    # Sets the default options that apply to every cassette.
    def default_cassette_options=(overrides)
      @default_cassette_options.merge!(overrides)
    end

    # Configures which libraries VCR will hook into to intercept HTTP requests.
    #
    # @example
    #   VCR.configure do |c|
    #     c.hook_into :webmock, :typhoeus
    #   end
    #
    # @param hooks [Array<Symbol>] List of libraries. Valid values are
    #  `:webmock`, `:typhoeus`, `:excon` and `:faraday`.
    # @raise [ArgumentError] when given an unsupported library name.
    # @raise [VCR::Errors::LibraryVersionTooLowError] when the version
    #  of a library you are using is too low for VCR to support.
    def hook_into(*hooks)
      hooks.each { |a| load_library_hook(a) }
      invoke_hook(:after_library_hooks_loaded)
    end

    # Specifies host(s) that VCR should ignore.
    #
    # @param hosts [Array<String>] List of hosts to ignore
    # @see #ignore_localhost=
    # @see #ignore_request
    def ignore_hosts(*hosts)
      VCR.request_ignorer.ignore_hosts(*hosts)
    end
    alias ignore_host ignore_hosts

    # Specifies host(s) that VCR should stop ignoring.
    #
    # @param hosts [Array<String>] List of hosts to unignore
    # @see #ignore_hosts
    def unignore_hosts(*hosts)
      VCR.request_ignorer.unignore_hosts(*hosts)
    end
    alias unignore_host unignore_hosts

    # Sets whether or not VCR should ignore localhost requests.
    #
    # @param value [Boolean] the value to set
    # @see #ignore_hosts
    # @see #ignore_request
    def ignore_localhost=(value)
      VCR.request_ignorer.ignore_localhost = value
    end

    # Defines what requests to ignore using a block.
    #
    # @example
    #   VCR.configure do |c|
    #     c.ignore_request do |request|
    #       uri = URI(request.uri)
    #       # ignore only localhost requests to port 7500
    #       uri.host == 'localhost' && uri.port == 7500
    #     end
    #   end
    #
    # @yield the callback
    # @yieldparam request [VCR::Request] the HTTP request
    # @yieldreturn [Boolean] whether or not to ignore the request
    def ignore_request(&block)
      VCR.request_ignorer.ignore_request(&block)
    end

    # Determines how VCR treats HTTP requests that are made when
    # no VCR cassette is in use. When set to `true`, requests made
    # when there is no VCR cassette in use will be allowed. When set
    # to `false` (the default), an {VCR::Errors::UnhandledHTTPRequestError}
    # will be raised for any HTTP request made when there is no
    # cassette in use.
    #
    # @overload allow_http_connections_when_no_cassette?
    #   @return [Boolean] whether or not HTTP connections are allowed
    #    when there is no cassette.
    # @overload allow_http_connections_when_no_cassette=
    #   @param value [Boolean] sets whether or not to allow HTTP
    #    connections when there is no cassette.
    attr_writer :allow_http_connections_when_no_cassette
    # @private (documented above)
    def allow_http_connections_when_no_cassette?
      !!@allow_http_connections_when_no_cassette
    end

    # Sets a parser for VCR to use when parsing query strings for request
    # comparisons.  The new parser must implement a method `call` that returns
    # an object which is both equalivant and consistent when given an HTTP
    # query string of possibly differing value ordering.
    #
    # * `#==    # => Boolean`
    #
    # The `#==` method must return true if both objects represent the
    # same query string.
    #
    # This defaults to `CGI.parse` from the ruby standard library.
    #
    # @overload query_parser
    #  @return [#call] the current query string parser object
    # @overload query_parser=
    #  @param value [#call] sets the query_parser
    attr_accessor :query_parser

    # Sets a parser for VCR to use when parsing URIs. The new parser
    # must implement a method `parse` that returns an instance of the
    # URI object. This URI object must implement the following
    # interface:
    #
    # * `scheme # => String`
    # * `host   # => String`
    # * `port   # => Fixnum`
    # * `path   # => String`
    # * `query  # => String`
    # * `#port=`
    # * `#query=`
    # * `#to_s  # => String`
    # * `#==    # => Boolean`
    #
    # The `#==` method must return true if both URI objects represent the
    # same URI.
    #
    # This defaults to `URI` from the ruby standard library.
    #
    # @overload uri_parser
    #  @return [#parse] the current URI parser object
    # @overload uri_parser=
    #  @param value [#parse] sets the uri_parser
    attr_accessor :uri_parser

    # Registers a request matcher for later use.
    #
    # @example
    #  VCR.configure do |c|
    #    c.register_request_matcher :port do |request_1, request_2|
    #      URI(request_1.uri).port == URI(request_2.uri).port
    #    end
    #  end
    #
    #  VCR.use_cassette("my_cassette", :match_requests_on => [:method, :host, :port]) do
    #    # ...
    #  end
    #
    # @param name [Symbol] the name of the request matcher
    # @yield the request matcher
    # @yieldparam request_1 [VCR::Request] One request
    # @yieldparam request_2 [VCR::Request] The other request
    # @yieldreturn [Boolean] whether or not these two requests should be considered
    #  equivalent
    def register_request_matcher(name, &block)
      VCR.request_matchers.register(name, &block)
    end

    # Sets up a {#before_record} and a {#before_playback} hook that will
    # insert a placeholder string in the cassette in place of another string.
    # You can use this as a generic way to interpolate a variable into the
    # cassette for a unique string. It's particularly useful for unique
    # sensitive strings like API keys and passwords.
    #
    # @example
    #   VCR.configure do |c|
    #     # Put "<GITHUB_API_KEY>" in place of the actual API key in
    #     # our cassettes so we don't have to commit to source control.
    #     c.filter_sensitive_data('<GITHUB_API_KEY>') { GithubClient.api_key }
    #
    #     # Put a "<USER_ID>" placeholder variable in our cassettes tagged with
    #     # :user_cassette since it can be different for different test runs.
    #     c.define_cassette_placeholder('<USER_ID>', :user_cassette) { User.last.id }
    #   end
    #
    # @param placeholder [String] The placeholder string.
    # @param tag [Symbol] Set this to apply this only to cassettes
    #  with a matching tag; otherwise it will apply to every cassette.
    # @yield block that determines what string to replace
    # @yieldparam interaction [(optional) VCR::HTTPInteraction::HookAware] the HTTP interaction
    # @yieldreturn the string to replace
    def define_cassette_placeholder(placeholder, tag = nil, &block)
      before_record(tag) do |interaction|
        orig_text = call_block(block, interaction)
        log "before_record: replacing #{orig_text.inspect} with #{placeholder.inspect}"
        interaction.filter!(orig_text, placeholder)
      end

      before_playback(tag) do |interaction|
        orig_text = call_block(block, interaction)
        log "before_playback: replacing #{orig_text.inspect} with #{placeholder.inspect}"
        interaction.filter!(placeholder, orig_text)
      end
    end
    alias filter_sensitive_data define_cassette_placeholder

    # Gets the registry of cassette serializers. Use it to register a custom serializer.
    #
    # @example
    #   VCR.configure do |c|
    #     c.cassette_serializers[:my_custom_serializer] = my_custom_serializer
    #   end
    #
    # @return [VCR::Cassette::Serializers] the cassette serializer registry object.
    # @note Custom serializers must implement the following interface:
    #
    #   * `file_extension      # => String`
    #   * `serialize(Hash)     # => String`
    #   * `deserialize(String) # => Hash`
    def cassette_serializers
      VCR.cassette_serializers
    end

    # Gets the registry of cassette persisters. Use it to register a custom persister.
    #
    # @example
    #   VCR.configure do |c|
    #     c.cassette_persisters[:my_custom_persister] = my_custom_persister
    #   end
    #
    # @return [VCR::Cassette::Persisters] the cassette persister registry object.
    # @note Custom persisters must implement the following interface:
    #
    #   * `persister[storage_key]`           # returns previously persisted content
    #   * `persister[storage_key] = content` # persists given content
    def cassette_persisters
      VCR.cassette_persisters
    end

    define_hook :before_record
    # Adds a callback that will be called before the recorded HTTP interactions
    # are serialized and written to disk.
    #
    # @example
    #  VCR.configure do |c|
    #    # Don't record transient 5xx errors
    #    c.before_record do |interaction|
    #      interaction.ignore! if interaction.response.status.code >= 500
    #    end
    #
    #    # Modify the response body for cassettes tagged with :twilio
    #    c.before_record(:twilio) do |interaction|
    #      interaction.response.body.downcase!
    #    end
    #  end
    #
    # @param tag [(optional) Symbol] Used to apply this hook to only cassettes that match
    #  the given tag.
    # @yield the callback
    # @yieldparam interaction [VCR::HTTPInteraction::HookAware] The interaction that will be
    #  serialized and written to disk.
    # @yieldparam cassette [(optional) VCR::Cassette] The current cassette.
    # @see #before_playback
    def before_record(tag = nil, &block)
      super(tag_filter_from(tag), &block)
    end

    define_hook :before_playback
    # Adds a callback that will be called before a previously recorded
    # HTTP interaction is loaded for playback.
    #
    # @example
    #  VCR.configure do |c|
    #    # Don't playback transient 5xx errors
    #    c.before_playback do |interaction|
    #      interaction.ignore! if interaction.response.status.code >= 500
    #    end
    #
    #    # Change a response header for playback
    #    c.before_playback(:twilio) do |interaction|
    #      interaction.response.headers['X-Foo-Bar'] = 'Bazz'
    #    end
    #  end
    #
    # @param tag [(optional) Symbol] Used to apply this hook to only cassettes that match
    #  the given tag.
    # @yield the callback
    # @yieldparam interaction [VCR::HTTPInteraction::HookAware] The interaction that is being
    #  loaded.
    # @yieldparam cassette [(optional) VCR::Cassette] The current cassette.
    # @see #before_record
    def before_playback(tag = nil, &block)
      super(tag_filter_from(tag), &block)
    end

    # Adds a callback that will be called with each HTTP request before it is made.
    #
    # @example
    #  VCR.configure do |c|
    #    c.before_http_request(:real?) do |request|
    #      puts "Request: #{request.method} #{request.uri}"
    #    end
    #  end
    #
    # @param filters [optional splat of #to_proc] one or more filters to apply.
    #   The objects provided will be converted to procs using `#to_proc`. If provided,
    #   the callback will only be invoked if these procs all return `true`.
    # @yield the callback
    # @yieldparam request [VCR::Request::Typed] the request that is being made
    # @see #after_http_request
    # @see #around_http_request
    define_hook :before_http_request

    define_hook :after_http_request, :prepend
    # Adds a callback that will be called with each HTTP request after it is complete.
    #
    # @example
    #  VCR.configure do |c|
    #    c.after_http_request(:ignored?) do |request, response|
    #      puts "Request: #{request.method} #{request.uri}"
    #      puts "Response: #{response.status.code}"
    #    end
    #  end
    #
    # @param filters [optional splat of #to_proc] one or more filters to apply.
    #   The objects provided will be converted to procs using `#to_proc`. If provided,
    #   the callback will only be invoked if these procs all return `true`.
    # @yield the callback
    # @yieldparam request [VCR::Request::Typed] the request that is being made
    # @yieldparam response [VCR::Response] the response from the request
    # @see #before_http_request
    # @see #around_http_request
    def after_http_request(*filters)
      super(*filters.map { |f| request_filter_from(f) })
    end

    # Adds a callback that will be executed around each HTTP request.
    #
    # @example
    #  VCR.configure do |c|
    #    c.around_http_request(lambda {|r| r.uri =~ /api.geocoder.com/}) do |request|
    #      # extract an address like "1700 E Pine St, Seattle, WA"
    #      # from a query like "address=1700+E+Pine+St%2C+Seattle%2C+WA"
    #      address = CGI.unescape(URI(request.uri).query.split('=').last)
    #      VCR.use_cassette("geocoding/#{address}", &request)
    #    end
    #  end
    #
    # @yield the callback
    # @yieldparam request [VCR::Request::FiberAware] the request that is being made
    # @raise [VCR::Errors::NotSupportedError] if the fiber library cannot be loaded.
    # @param filters [optional splat of #to_proc] one or more filters to apply.
    #   The objects provided will be converted to procs using `#to_proc`. If provided,
    #   the callback will only be invoked if these procs all return `true`.
    # @note This method can only be used on ruby interpreters that support
    #  fibers (i.e. 1.9+). On 1.8 you can use separate `before_http_request` and
    #  `after_http_request` hooks.
    # @note You _must_ call `request.proceed` or pass the request as a proc on to a
    #  method that yields to a block (i.e. `some_method(&request)`).
    # @see #before_http_request
    # @see #after_http_request
    def around_http_request(*filters, &block)
      unless VCR.fibers_available?
        raise Errors::NotSupportedError.new \
          "VCR::Configuration#around_http_request requires fibers, " +
          "which are not available on your ruby intepreter."
      end

      fibers = {}
      fiber_errors = {}
      hook_allowed, hook_declaration = false, caller.first
      before_http_request(*filters) do |request|
        hook_allowed = true
        start_new_fiber_for(request, fibers, fiber_errors, hook_declaration, block)
      end

      after_http_request(lambda { hook_allowed }) do |request, response|
        fiber = fibers.delete(Thread.current)
        resume_fiber(fiber, fiber_errors, response, hook_declaration)
      end
    end

    # Configures RSpec to use a VCR cassette for any example
    # tagged with `:vcr`.
    def configure_rspec_metadata!
      unless @rspec_metadata_configured
        VCR::RSpec::Metadata.configure!
        @rspec_metadata_configured = true
      end
    end

    # An object to log debug output to.
    #
    # @overload debug_logger
    #   @return [#puts] the logger
    # @overload debug_logger=(logger)
    #   @param logger [#puts] the logger
    #   @return [void]
    # @example
    #   VCR.configure do |c|
    #     c.debug_logger = $stderr
    #   end
    # @example
    #   VCR.configure do |c|
    #     c.debug_logger = File.open('vcr.log', 'w')
    #   end
    attr_reader :debug_logger
    # @private (documented above)
    def debug_logger=(value)
      @debug_logger = value

      if value
        @logger = Logger.new(value)
      else
        @logger = Logger::Null
      end
    end

    # @private
    # Logger object that provides logging APIs and helper methods.
    attr_reader :logger

    # Sets a callback that determines whether or not to base64 encode
    # the bytes of a request or response body during serialization in
    # order to preserve them exactly.
    #
    # @example
    #   VCR.configure do |c|
    #     c.preserve_exact_body_bytes do |http_message|
    #       http_message.body.encoding.name == 'ASCII-8BIT' ||
    #       !http_message.body.valid_encoding?
    #     end
    #   end
    #
    # @yield the callback
    # @yieldparam http_message [#body, #headers] the `VCR::Request` or `VCR::Response` object being serialized
    # @yieldparam cassette [VCR::Cassette] the cassette the http message belongs to
    # @yieldreturn [Boolean] whether or not to preserve the exact bytes for the body of the given HTTP message
    # @return [void]
    # @see #preserve_exact_body_bytes_for?
    # @note This is usually only necessary when the HTTP server returns a response
    #  with a non-standard encoding or with a body containing invalid bytes for the given
    #  encoding. Note that when you set this, and the block returns true, you sacrifice
    #  the human readability of the data in the cassette.
    define_hook :preserve_exact_body_bytes

    # @return [Boolean] whether or not the body of the given HTTP message should
    #  be base64 encoded during serialization in order to preserve the bytes exactly.
    # @param http_message [#body, #headers] the `VCR::Request` or `VCR::Response` object being serialized
    # @see #preserve_exact_body_bytes
    def preserve_exact_body_bytes_for?(http_message)
      invoke_hook(:preserve_exact_body_bytes, http_message, VCR.current_cassette).any?
    end

  private

    def initialize
      @allow_http_connections_when_no_cassette = nil
      @rspec_metadata_configured = false
      @default_cassette_options = {
        :record            => :once,
        :record_on_error   => true,
        :match_requests_on => RequestMatcherRegistry::DEFAULT_MATCHERS,
        :allow_unused_http_interactions => true,
        :drop_unused_requests => false,
        :serialize_with    => :yaml,
        :persist_with      => :file_system,
        :persister_options => {}
      }

      self.uri_parser = URI
      self.query_parser = CGI.method(:parse)
      self.debug_logger = nil

      register_built_in_hooks
    end

    def load_library_hook(hook)
      file = "vcr/library_hooks/#{hook}"
      require file
    rescue LoadError => e
      raise e unless e.message.include?(file) # in case WebMock itself is not available
      raise ArgumentError.new("#{hook.inspect} is not a supported VCR HTTP library hook.")
    end

    def resume_fiber(fiber, fiber_errors, response, hook_declaration)
      raise fiber_errors[Thread.current] if fiber_errors[Thread.current]
      fiber.resume(response)
    rescue FiberError => ex
      raise Errors::AroundHTTPRequestHookError.new \
        "Your around_http_request hook declared at #{hook_declaration}" \
        " must call #proceed on the yielded request but did not. " \
        "(actual error: #{ex.class}: #{ex.message})"
    end

    def create_fiber_for(fiber_errors, hook_declaration, proc)
      current_thread = Thread.current
      Fiber.new do |*args, &block|
        begin
          # JRuby Fiber runs in a separate thread, so we need to make this Fiber
          # use the context of the calling thread
          VCR.link_context(current_thread, Fiber.current) if RUBY_PLATFORM == 'java'
          proc.call(*args, &block)
        rescue StandardError => ex
          # Fiber errors get swallowed, so we re-raise the error in the parent
          # thread (see resume_fiber)
          fiber_errors[current_thread] = ex
          raise
        ensure
          VCR.unlink_context(Fiber.current) if RUBY_PLATFORM == 'java'
        end
      end
    end

    def start_new_fiber_for(request, fibers, fiber_errors, hook_declaration, proc)
      fiber = create_fiber_for(fiber_errors, hook_declaration, proc)
      fibers[Thread.current] = fiber
      fiber.resume(Request::FiberAware.new(request))
    end

    def tag_filter_from(tag)
      return lambda { true } unless tag
      lambda { |_, cassette| cassette.tags.include?(tag) }
    end

    def request_filter_from(object)
      return object unless object.is_a?(Symbol)
      lambda { |arg| arg.send(object) }
    end

    def register_built_in_hooks
      before_playback(:recompress_response) do |interaction|
        interaction.response.recompress if interaction.response.vcr_decompressed?
      end

      before_playback(:update_content_length_header) do |interaction|
        interaction.response.update_content_length_header
      end

      before_record(:decode_compressed_response) do |interaction|
        interaction.response.decompress if interaction.response.compressed?
      end

      preserve_exact_body_bytes do |http_message, cassette|
        cassette && cassette.tags.include?(:preserve_exact_body_bytes)
      end
    end

    def log_prefix
      "[VCR::Configuration] "
    end

    # @private
    define_hook :after_library_hooks_loaded
  end
end
