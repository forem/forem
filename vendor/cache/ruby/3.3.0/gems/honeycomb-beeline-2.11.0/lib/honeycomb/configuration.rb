# frozen_string_literal: true

require "socket"
require "honeycomb/propagation/default"
require "honeycomb/propagation/default_modern"

module Honeycomb
  # Used to configure the Honeycomb client
  class Configuration
    attr_accessor :write_key,
                  :api_host,
                  :debug

    attr_writer :service_name, :client, :host_name, :dataset
    attr_reader :error_backtrace_limit

    def initialize
      @write_key = ENV["HONEYCOMB_WRITEKEY"]
      @dataset = ENV["HONEYCOMB_DATASET"]
      @service_name = ENV["HONEYCOMB_SERVICE"]
      @debug = ENV.key?("HONEYCOMB_DEBUG")
      @error_backtrace_limit = 0
      @client = nil
    end

    def classic?
      @write_key.nil? || @write_key.length == 32
    end

    def service_name
      return @service_name if service_name_given?
      return @dataset if classic?

      "unknown_service:" + $PROGRAM_NAME.split("/").last
    end

    def dataset
      return @dataset if classic?
      return "unknown_service" if service_name.nil?

      stripped_service_name = service_name.strip

      warn("found extra whitespace in service name") if stripped_service_name != service_name

      if stripped_service_name.empty? || stripped_service_name.start_with?("unknown_service")
        # don't use process name in dataset
        "unknown_service"
      else
        stripped_service_name
      end
    end

    def error_backtrace_limit=(val)
      @error_backtrace_limit = Integer(val)
    end

    def client
      # memoized:
      # either the user has supplied a pre-configured Libhoney client
      @client ||=
        # or we'll create one and return it from here on
        if debug
          Libhoney::LogClient.new
        else
          validate_options
          Libhoney::Client.new(**libhoney_client_options)
        end
    end

    def after_initialize(client)
      super(client) if defined?(super)
    end

    def host_name
      # Send the heroku dyno name instead of hostname if available
      @host_name || ENV["DYNO"] || Socket.gethostname
    end

    def presend_hook(&hook)
      if block_given?
        @presend_hook = hook
      else
        @presend_hook
      end
    end

    def sample_hook(&hook)
      if block_given?
        @sample_hook = hook
      else
        @sample_hook
      end
    end

    def http_trace_parser_hook(&hook)
      if block_given?
        @http_trace_parser_hook = hook
      elsif @http_trace_parser_hook
        @http_trace_parser_hook
      elsif classic?
        DefaultPropagation::UnmarshalTraceContext.method(:parse_rack_env)
      else
        # by default we try to parse incoming honeycomb traces
        DefaultModernPropagation::UnmarshalTraceContext.method(:parse_rack_env)
      end
    end

    def http_trace_propagation_hook(&hook)
      if block_given?
        @http_trace_propagation_hook = hook
      elsif @http_trace_propagation_hook
        @http_trace_propagation_hook
      elsif classic?
        HoneycombPropagation::MarshalTraceContext.method(:parse_faraday_env)
      else
        # by default we send outgoing honeycomb trace headers
        HoneycombModernPropagation::MarshalTraceContext.method(:parse_faraday_env)
      end
    end

    private

    def libhoney_client_options
      {
        writekey: write_key,
        dataset: dataset,
        user_agent_addition: Honeycomb::Beeline::USER_AGENT_SUFFIX,
      }.tap do |options|
        # only set the API host for the client if one has been given
        options[:api_host] = api_host if api_host
      end
    end

    def validate_options
      warn("missing write_key") if write_key.nil? || write_key.empty?
      if classic?
        validate_options_classic
      else
        warn("service_name is unknown, will set to " + service_name) \
          if service_name.start_with?("unknown_service")
        warn("dataset will be ignored, sending data to " + service_name) \
          if dataset_given?
      end
    end

    def validate_options_classic
      warn("empty service_name option") unless service_name_given?
      warn("empty dataset option") unless dataset_given?
    end

    def service_name_given?
      # check the instance variables, not the accessor method
      @service_name && !@service_name.empty?
    end

    def dataset_given?
      @dataset && !@dataset.empty?
    end
  end
end
