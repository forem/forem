# frozen_string_literal: true

require "cgi"

module Stripe
  module Util
    # Options that a user is allowed to specify.
    OPTS_USER_SPECIFIED = Set[
      :api_key,
      :idempotency_key,
      :stripe_account,
      :stripe_version
    ].freeze

    # Options that should be copyable from one StripeObject to another
    # including options that may be internal.
    OPTS_COPYABLE = (
      OPTS_USER_SPECIFIED + Set[:api_base]
    ).freeze

    # Options that should be persisted between API requests. This includes
    # client, which is an object containing an HTTP client to reuse.
    OPTS_PERSISTABLE = (
      OPTS_USER_SPECIFIED + Set[:client] - Set[:idempotency_key]
    ).freeze

    def self.objects_to_ids(obj)
      case obj
      when APIResource
        obj.id
      when Hash
        res = {}
        obj.each { |k, v| res[k] = objects_to_ids(v) unless v.nil? }
        res
      when Array
        obj.map { |v| objects_to_ids(v) }
      else
        obj
      end
    end

    def self.object_classes
      @object_classes ||= Stripe::ObjectTypes.object_names_to_classes
    end

    def self.object_name_matches_class?(object_name, klass)
      Util.object_classes[object_name] == klass
    end

    # Adds a custom method to a resource class. This is used to add support for
    # non-CRUDL API requests, e.g. capturing charges. custom_method takes the
    # following parameters:
    # - name: the name of the custom method to create (as a symbol)
    # - http_verb: the HTTP verb for the API request (:get, :post, or :delete)
    # - http_path: the path to append to the resource's URL. If not provided,
    #              the name is used as the path
    # - resource: the resource implementation class
    # - target: the class that custom static method will be added to
    #
    # For example, this call:
    #     custom_method :capture, http_verb: post
    # adds a `capture` class method to the resource class that, when called,
    # will send a POST request to `/v1/<object_name>/capture`.
    def self.custom_method(resource, target, name, http_verb, http_path)
      unless %i[get post delete].include?(http_verb)
        raise ArgumentError,
              "Invalid http_verb value: #{http_verb.inspect}. Should be one " \
              "of :get, :post or :delete."
      end
      unless target.respond_to?(:resource_url)
        raise ArgumentError,
              "Invalid target value: #{target}. Target class should have a " \
              "`resource_url` method."
      end
      http_path ||= name.to_s
      target.define_singleton_method(name) do |id, params = {}, opts = {}|
        unless id.is_a?(String)
          raise ArgumentError,
                "id should be a string representing the ID of an API resource"
        end

        url = "#{target.resource_url}/"\
              "#{CGI.escape(id)}/"\
              "#{CGI.escape(http_path)}"

        resp, opts = resource.execute_resource_request(
          http_verb,
          url,
          params,
          opts
        )

        Util.convert_to_stripe_object(resp.data, opts)
      end
    end

    # Converts a hash of fields or an array of hashes into a +StripeObject+ or
    # array of +StripeObject+s. These new objects will be created as a concrete
    # type as dictated by their `object` field (e.g. an `object` value of
    # `charge` would create an instance of +Charge+), but if `object` is not
    # present or of an unknown type, the newly created instance will fall back
    # to being a +StripeObject+.
    #
    # ==== Attributes
    #
    # * +data+ - Hash of fields and values to be converted into a StripeObject.
    # * +opts+ - Options for +StripeObject+ like an API key that will be reused
    #   on subsequent API calls.
    def self.convert_to_stripe_object(data, opts = {})
      opts = normalize_opts(opts)

      case data
      when Array
        data.map { |i| convert_to_stripe_object(i, opts) }
      when Hash
        # Try converting to a known object class.  If none available, fall back
        # to generic StripeObject
        object_classes.fetch(data[:object], StripeObject)
                      .construct_from(data, opts)
      else
        data
      end
    end

    def self.log_error(message, data = {})
      config = data.delete(:config) || Stripe.config
      logger = config.logger || Stripe.logger
      if !logger.nil? ||
         !config.log_level.nil? && config.log_level <= Stripe::LEVEL_ERROR
        log_internal(message, data, color: :cyan, level: Stripe::LEVEL_ERROR,
                                    logger: Stripe.logger, out: $stderr)
      end
    end

    def self.log_info(message, data = {})
      config = data.delete(:config) || Stripe.config
      logger = config.logger || Stripe.logger
      if !logger.nil? ||
         !config.log_level.nil? && config.log_level <= Stripe::LEVEL_INFO
        log_internal(message, data, color: :cyan, level: Stripe::LEVEL_INFO,
                                    logger: Stripe.logger, out: $stdout)
      end
    end

    def self.log_debug(message, data = {})
      config = data.delete(:config) || Stripe.config
      logger = config.logger || Stripe.logger
      if !logger.nil? ||
         !config.log_level.nil? && config.log_level <= Stripe::LEVEL_DEBUG
        log_internal(message, data, color: :blue, level: Stripe::LEVEL_DEBUG,
                                    logger: Stripe.logger, out: $stdout)
      end
    end

    def self.symbolize_names(object)
      case object
      when Hash
        new_hash = {}
        object.each do |key, value|
          key = (begin
                   key.to_sym
                 rescue StandardError
                   key
                 end) || key
          new_hash[key] = symbolize_names(value)
        end
        new_hash
      when Array
        object.map { |value| symbolize_names(value) }
      else
        object
      end
    end

    # Encodes a hash of parameters in a way that's suitable for use as query
    # parameters in a URI or as form parameters in a request body. This mainly
    # involves escaping special characters from parameter keys and values (e.g.
    # `&`).
    def self.encode_parameters(params)
      Util.flatten_params(params)
          .map { |k, v| "#{url_encode(k)}=#{url_encode(v)}" }.join("&")
    end

    # Encodes a string in a way that makes it suitable for use in a set of
    # query parameters in a URI or in a set of form parameters in a request
    # body.
    def self.url_encode(key)
      CGI.escape(key.to_s).
        # Don't use strict form encoding by changing the square bracket control
        # characters back to their literals. This is fine by the server, and
        # makes these parameter strings easier to read.
        gsub("%5B", "[").gsub("%5D", "]")
    end

    def self.flatten_params(params, parent_key = nil)
      result = []

      # do not sort the final output because arrays (and arrays of hashes
      # especially) can be order sensitive, but do sort incoming parameters
      params.each do |key, value|
        calculated_key = parent_key ? "#{parent_key}[#{key}]" : key.to_s
        if value.is_a?(Hash)
          result += flatten_params(value, calculated_key)
        elsif value.is_a?(Array)
          result += flatten_params_array(value, calculated_key)
        else
          result << [calculated_key, value]
        end
      end

      result
    end

    def self.flatten_params_array(value, calculated_key)
      result = []
      value.each_with_index do |elem, i|
        if elem.is_a?(Hash)
          result += flatten_params(elem, "#{calculated_key}[#{i}]")
        elsif elem.is_a?(Array)
          result += flatten_params_array(elem, calculated_key)
        else
          result << ["#{calculated_key}[#{i}]", elem]
        end
      end
      result
    end

    # `Time.now` can be unstable in cases like an administrator manually
    # updating its value or a reconcilation via NTP. For this reason, prefer
    # the use of the system's monotonic clock especially where comparing times
    # to calculate an elapsed duration.
    #
    # Shortcut for getting monotonic time, mostly for purposes of line length
    # and test stubbing. Returns time in seconds since the event used for
    # monotonic reference purposes by the platform (e.g. system boot time).
    def self.monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def self.normalize_id(id)
      if id.is_a?(Hash) # overloaded id
        params_hash = id.dup
        id = params_hash.delete(:id)
      else
        params_hash = {}
      end
      [id, params_hash]
    end

    # The secondary opts argument can either be a string or hash
    # Turn this value into an api_key and a set of headers
    def self.normalize_opts(opts)
      case opts
      when String
        { api_key: opts }
      when Hash
        check_api_key!(opts.fetch(:api_key)) if opts.key?(:api_key)
        # Explicitly use dup here instead of clone to avoid preserving freeze
        # state on input params.
        opts.dup
      else
        raise TypeError, "normalize_opts expects a string or a hash"
      end
    end

    def self.check_string_argument!(key)
      raise TypeError, "argument must be a string" unless key.is_a?(String)

      key
    end

    def self.check_api_key!(key)
      raise TypeError, "api_key must be a string" unless key.is_a?(String)

      key
    end

    # Normalizes header keys so that they're all lower case and each
    # hyphen-delimited section starts with a single capitalized letter. For
    # example, `request-id` becomes `Request-Id`. This is useful for extracting
    # certain key values when the user could have set them with a variety of
    # diffent naming schemes.
    def self.normalize_headers(headers)
      headers.each_with_object({}) do |(k, v), new_headers|
        k = k.to_s.tr("_", "-") if k.is_a?(Symbol)
        k = k.split("-").reject(&:empty?).map(&:capitalize).join("-")

        new_headers[k] = v
      end
    end

    # Generates a Dashboard link to inspect a request ID based off of a request
    # ID value and an API key, which is used to attempt to extract whether the
    # environment is livemode or testmode.
    def self.request_id_dashboard_url(request_id, api_key)
      env = !api_key.nil? && api_key.start_with?("sk_live") ? "live" : "test"
      "https://dashboard.stripe.com/#{env}/logs/#{request_id}"
    end

    # Constant time string comparison to prevent timing attacks
    # Code borrowed from ActiveSupport
    def self.secure_compare(str_a, str_b)
      return false unless str_a.bytesize == str_b.bytesize

      l = str_a.unpack "C#{str_a.bytesize}"

      res = 0
      str_b.each_byte { |byte| res |= byte ^ l.shift }
      res.zero?
    end

    #
    # private
    #

    COLOR_CODES = {
      black: 0, light_black: 60,
      red: 1, light_red: 61,
      green: 2, light_green: 62,
      yellow: 3, light_yellow: 63,
      blue: 4, light_blue: 64,
      magenta: 5, light_magenta: 65,
      cyan: 6, light_cyan: 66,
      white: 7, light_white: 67,
      default: 9,
    }.freeze
    private_constant :COLOR_CODES

    # Uses an ANSI escape code to colorize text if it's going to be sent to a
    # TTY.
    def self.colorize(val, color, isatty)
      return val unless isatty

      mode = 0 # default
      foreground = 30 + COLOR_CODES.fetch(color)
      background = 40 + COLOR_CODES.fetch(:default)

      "\033[#{mode};#{foreground};#{background}m#{val}\033[0m"
    end
    private_class_method :colorize

    # Turns an integer log level into a printable name.
    def self.level_name(level)
      case level
      when LEVEL_DEBUG then "debug"
      when LEVEL_ERROR then "error"
      when LEVEL_INFO  then "info"
      else level
      end
    end
    private_class_method :level_name

    def self.log_internal(message, data = {}, color:, level:, logger:, out:)
      data_str = data.reject { |_k, v| v.nil? }
                     .map do |(k, v)|
        format("%<key>s=%<value>s",
               key: colorize(k, color, logger.nil? && !out.nil? && out.isatty),
               value: wrap_logfmt_value(v))
      end.join(" ")

      if !logger.nil?
        # the library's log levels are mapped to the same values as the
        # standard library's logger
        logger.log(level,
                   format("message=%<message>s %<data_str>s",
                          message: wrap_logfmt_value(message),
                          data_str: data_str))
      elsif out.isatty
        out.puts format("%<level>s %<message>s %<data_str>s",
                        level: colorize(level_name(level)[0, 4].upcase,
                                        color, out.isatty),
                        message: message,
                        data_str: data_str)
      else
        out.puts format("message=%<message>s level=%<level>s %<data_str>s",
                        message: wrap_logfmt_value(message),
                        level: level_name(level),
                        data_str: data_str)
      end
    end
    private_class_method :log_internal

    # Wraps a value in double quotes if it looks sufficiently complex so that
    # it can be read by logfmt parsers.
    def self.wrap_logfmt_value(val)
      # If value is any kind of number, just allow it to be formatted directly
      # to a string (this will handle integers or floats).
      return val if val.is_a?(Numeric)

      # Hopefully val is a string, but protect in case it's not.
      val = val.to_s

      if %r{[^\w\-/]} =~ val
        # If the string contains any special characters, escape any double
        # quotes it has, remove newlines, and wrap the whole thing in quotes.
        format(%("%<value>s"), value: val.gsub('"', '\"').delete("\n"))
      else
        # Otherwise use the basic value if it looks like a standard set of
        # characters (and allow a few special characters like hyphens, and
        # slashes)
        val
      end
    end
    private_class_method :wrap_logfmt_value
  end
end
