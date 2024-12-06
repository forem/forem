require 'logger'

module Rack
  class Cors
    HTTP_ORIGIN   = 'HTTP_ORIGIN'.freeze
    HTTP_X_ORIGIN = 'HTTP_X_ORIGIN'.freeze

    HTTP_ACCESS_CONTROL_REQUEST_METHOD  = 'HTTP_ACCESS_CONTROL_REQUEST_METHOD'.freeze
    HTTP_ACCESS_CONTROL_REQUEST_HEADERS = 'HTTP_ACCESS_CONTROL_REQUEST_HEADERS'.freeze

    PATH_INFO      = 'PATH_INFO'.freeze
    REQUEST_METHOD = 'REQUEST_METHOD'.freeze

    RACK_LOGGER = 'rack.logger'.freeze
    RACK_CORS   =
    # retaining the old key for backwards compatibility
    ENV_KEY     = 'rack.cors'.freeze

    OPTIONS     = 'OPTIONS'.freeze
    VARY        = 'Vary'.freeze

    DEFAULT_VARY_HEADERS = ['Origin'].freeze

    # All CORS routes need to accept CORS simple headers at all times
    # {https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers}
    CORS_SIMPLE_HEADERS = ['accept', 'accept-language', 'content-language', 'content-type'].freeze

    def initialize(app, opts={}, &block)
      @app = app
      @debug_mode = !!opts[:debug]
      @logger = @logger_proc = nil

      if logger = opts[:logger]
        if logger.respond_to? :call
          @logger_proc = opts[:logger]
        else
          @logger = logger
        end
      end

      if block_given?
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
      end
    end

    def debug?
      @debug_mode
    end

    def allow(&block)
      all_resources << (resources = Resources.new)

      if block.arity == 1
        block.call(resources)
      else
        resources.instance_eval(&block)
      end
    end

    def call(env)
      env[HTTP_ORIGIN] ||= env[HTTP_X_ORIGIN] if env[HTTP_X_ORIGIN]

      path = evaluate_path(env)

      add_headers = nil
      if env[HTTP_ORIGIN]
        debug(env) do
          [ 'Incoming Headers:',
            "  Origin: #{env[HTTP_ORIGIN]}",
            "  Path-Info: #{path}",
            "  Access-Control-Request-Method: #{env[HTTP_ACCESS_CONTROL_REQUEST_METHOD]}",
            "  Access-Control-Request-Headers: #{env[HTTP_ACCESS_CONTROL_REQUEST_HEADERS]}"
            ].join("\n")
        end

        if env[REQUEST_METHOD] == OPTIONS && env[HTTP_ACCESS_CONTROL_REQUEST_METHOD]
          return [400, {}, []] unless Rack::Utils.valid_path?(path)
          headers = process_preflight(env, path)
          debug(env) do
            "Preflight Headers:\n" +
                headers.collect{|kv| "  #{kv.join(': ')}"}.join("\n")
          end
          return [200, headers, []]
        else
          add_headers = process_cors(env, path)
        end
      else
        Result.miss(env, Result::MISS_NO_ORIGIN)
      end

      # This call must be done BEFORE calling the app because for some reason
      # env[PATH_INFO] gets changed after that and it won't match. (At least
      # in rails 4.1.6)
      vary_resource = resource_for_path(path)

      status, headers, body = @app.call env

      if add_headers
        headers = add_headers.merge(headers)
        debug(env) do
          add_headers.each_pair do |key, value|
            if headers.has_key?(key)
              headers["X-Rack-CORS-Original-#{key}"] = value
            end
          end
        end
      end

      # Vary header should ALWAYS mention Origin if there's ANY chance for the
      # response to be different depending on the Origin header value.
      # Better explained here: http://www.fastly.com/blog/best-practices-for-using-the-vary-header/
      if vary_resource
        vary = headers[VARY]
        cors_vary_headers = if vary_resource.vary_headers && vary_resource.vary_headers.any?
          vary_resource.vary_headers
        else
          DEFAULT_VARY_HEADERS
        end
        headers[VARY] = ((vary ? ([vary].flatten.map { |v| v.split(/,\s*/) }.flatten) : []) + cors_vary_headers).uniq.join(', ')
      end

      if debug? && result = env[RACK_CORS]
        result.append_header(headers)
      end

      [status, headers, body]
    end

    protected
      def debug(env, message = nil, &block)
        (@logger || select_logger(env)).debug(message, &block) if debug?
      end

      def select_logger(env)
        @logger = if @logger_proc
          logger_proc = @logger_proc
          @logger_proc = nil
          logger_proc.call

        elsif defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger

        elsif env[RACK_LOGGER]
          env[RACK_LOGGER]

        else
          ::Logger.new(STDOUT).tap { |logger| logger.level = ::Logger::Severity::DEBUG }
        end
      end

      def evaluate_path(env)
        path = env[PATH_INFO]

        if path
          path = Rack::Utils.unescape_path(path)

          if Rack::Utils.valid_path?(path)
            path = Rack::Utils.clean_path_info(path)
          end
        end

        path
      end

      def all_resources
        @all_resources ||= []
      end

      def process_preflight(env, path)
        result = Result.preflight(env)

        resource, error = match_resource(path, env)
        unless resource
          result.miss(error)
          return {}
        end

        return resource.process_preflight(env, result)
      end

      def process_cors(env, path)
        resource, error = match_resource(path, env)
        if resource
          Result.hit(env)
          cors = resource.to_headers(env)
          cors

        else
          Result.miss(env, error)
          nil
        end
      end

      def resource_for_path(path_info)
        all_resources.each do |r|
          if found = r.resource_for_path(path_info)
            return found
          end
        end
        nil
      end

      def match_resource(path, env)
        origin = env[HTTP_ORIGIN]

        origin_matched = false
        all_resources.each do |r|
          if r.allow_origin?(origin, env)
            origin_matched = true
            if found = r.match_resource(path, env)
              return [found, nil]
            end
          end
        end

        [nil, origin_matched ? Result::MISS_NO_PATH : Result::MISS_NO_ORIGIN]
      end

      class Result
        HEADER_KEY = 'X-Rack-CORS'.freeze

        MISS_NO_ORIGIN = 'no-origin'.freeze
        MISS_NO_PATH   = 'no-path'.freeze

        MISS_NO_METHOD   = 'no-method'.freeze
        MISS_DENY_METHOD = 'deny-method'.freeze
        MISS_DENY_HEADER = 'deny-header'.freeze

        attr_accessor :preflight, :hit, :miss_reason

        def hit?
          !!hit
        end

        def preflight?
          !!preflight
        end

        def miss(reason)
          self.hit = false
          self.miss_reason = reason
        end

        def self.hit(env)
          r = Result.new
          r.preflight = false
          r.hit = true
          env[RACK_CORS] = r
        end

        def self.miss(env, reason)
          r = Result.new
          r.preflight = false
          r.hit = false
          r.miss_reason = reason
          env[RACK_CORS] = r
        end

        def self.preflight(env)
          r = Result.new
          r.preflight = true
          env[RACK_CORS] = r
        end


        def append_header(headers)
          headers[HEADER_KEY] = if hit?
            preflight? ? 'preflight-hit' : 'hit'
          else
            [
              (preflight? ? 'preflight-miss' : 'miss'),
              miss_reason
            ].join('; ')
          end
        end
      end

      class Resources

        attr_reader :resources

        def initialize
          @origins = []
          @resources = []
          @public_resources = false
        end

        def origins(*args, &blk)
          @origins = args.flatten.reject{ |s| s == '' }.map do |n|
            case n
            when Proc,
                 Regexp,
                 /^https?:\/\//,
                 'file://'        then n
            when '*'              then @public_resources = true; n
            else                  Regexp.compile("^[a-z][a-z0-9.+-]*:\\\/\\\/#{Regexp.quote(n)}$")
            end
          end.flatten
          @origins.push(blk) if blk
        end

        def resource(path, opts={})
          @resources << Resource.new(public_resources?, path, opts)
        end

        def public_resources?
          @public_resources
        end

        def allow_origin?(source,env = {})
          return true if public_resources?

          return !! @origins.detect do |origin|
            if origin.is_a?(Proc)
              origin.call(source,env)
            else
              origin === source
            end
          end
        end

        def match_resource(path, env)
          @resources.detect { |r| r.match?(path, env) }
        end

        def resource_for_path(path)
          @resources.detect { |r| r.matches_path?(path) }
        end

      end

      class Resource
        class CorsMisconfigurationError < StandardError
          def message
            "Allowing credentials for wildcard origins is insecure."\
            " Please specify more restrictive origins or set 'credentials' to false in your CORS configuration."
          end
        end

        attr_accessor :path, :methods, :headers, :expose, :max_age, :credentials, :pattern, :if_proc, :vary_headers

        def initialize(public_resource, path, opts={})
          raise CorsMisconfigurationError if public_resource && opts[:credentials] == true

          self.path         = path
          self.credentials  = public_resource ? false : (opts[:credentials] == true)
          self.max_age      = opts[:max_age] || 7200
          self.pattern      = compile(path)
          self.if_proc      = opts[:if]
          self.vary_headers = opts[:vary] && [opts[:vary]].flatten
          @public_resource  = public_resource

          self.headers = case opts[:headers]
          when :any then :any
          when nil then nil
          else
            [opts[:headers]].flatten.collect{|h| h.downcase}
          end

          self.methods = case opts[:methods]
          when :any then [:get, :head, :post, :put, :patch, :delete, :options]
          else
            ensure_enum(opts[:methods]) || [:get]
          end.map{|e| e.to_s }

          self.expose = opts[:expose] ? [opts[:expose]].flatten : nil
        end

        def matches_path?(path)
          pattern =~ path
        end

        def match?(path, env)
          matches_path?(path) && (if_proc.nil? || if_proc.call(env))
        end

        def process_preflight(env, result)
          headers = {}

          request_method = env[HTTP_ACCESS_CONTROL_REQUEST_METHOD]
          if request_method.nil?
            result.miss(Result::MISS_NO_METHOD) and return headers
          end
          if !methods.include?(request_method.downcase)
            result.miss(Result::MISS_DENY_METHOD) and return headers
          end

          request_headers = env[HTTP_ACCESS_CONTROL_REQUEST_HEADERS]
          if request_headers && !allow_headers?(request_headers)
            result.miss(Result::MISS_DENY_HEADER) and return headers
          end

          result.hit = true
          headers.merge(to_preflight_headers(env))
        end

        def to_headers(env)
          h = {
            'Access-Control-Allow-Origin'     => origin_for_response_header(env[HTTP_ORIGIN]),
            'Access-Control-Allow-Methods'    => methods.collect{|m| m.to_s.upcase}.join(', '),
            'Access-Control-Expose-Headers'   => expose.nil? ? '' : expose.join(', '),
            'Access-Control-Max-Age'          => max_age.to_s }
          h['Access-Control-Allow-Credentials'] = 'true' if credentials
          h
        end

        protected
          def public_resource?
            @public_resource
          end

          def origin_for_response_header(origin)
            return '*' if public_resource?
            origin
          end

          def to_preflight_headers(env)
            h = to_headers(env)
            if env[HTTP_ACCESS_CONTROL_REQUEST_HEADERS]
              h.merge!('Access-Control-Allow-Headers' => env[HTTP_ACCESS_CONTROL_REQUEST_HEADERS])
            end
            h
          end

          def allow_headers?(request_headers)
            headers = self.headers || []
            if headers == :any
              return true
            end
            request_headers = request_headers.split(/,\s*/) if request_headers.kind_of?(String)
            request_headers.all? do |header|
              header = header.downcase
              CORS_SIMPLE_HEADERS.include?(header) || headers.include?(header)
            end
          end

          def ensure_enum(v)
            return nil if v.nil?
            [v].flatten
          end

          def compile(path)
            if path.respond_to? :to_str
              special_chars = %w{. + ( )}
              pattern =
                path.to_str.gsub(/((:\w+)|\/\*|[\*#{special_chars.join}])/) do |match|
                  case match
                  when "/*"
                    "\\/?(.*?)"
                  when "*"
                    "(.*?)"
                  when *special_chars
                    Regexp.escape(match)
                  else
                    "([^/?&#]+)"
                  end
                end
              /^#{pattern}$/
            elsif path.respond_to? :match
              path
            else
              raise TypeError, path
            end
          end
      end

  end
end
