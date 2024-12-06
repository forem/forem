require 'addressable/uri'
require 'time'
require 'json'
require 'forwardable'

require 'libhoney/null_transmission'

module Libhoney
  ##
  # This is a library to allow you to send events to Honeycomb from within your
  # Ruby application.
  #
  # @example Send a simple event
  #   require 'libhoney'
  #   honey = Libhoney.new(writekey, dataset, sample_rate)
  #
  #   evt = honey.event
  #   evt.add(pglatency: 100)
  #   honey.send(evt)
  #
  #   # repeat creating and sending events until your program is finished
  #
  #   honey.close
  #
  # @example Override the default timestamp on an event
  #   one_hour_ago = Time.now - 3600
  #
  #   evt = libhoney.event
  #   evt.add_fields(useful_fields)
  #   evt.timestamp = one_hour_ago
  #   evt.send
  #
  class Client
    extend Forwardable

    API_HOST = 'https://api.honeycomb.io/'.freeze
    DEFAULT_DATASET = 'unknown_dataset'.freeze

    # Instantiates libhoney and prepares it to send events to Honeycomb.
    #
    # @param writekey [String] the Honeycomb API key with which to authenticate
    #   this request (required)
    # @param dataset [String] the Honeycomb dataset into which to send events (required)
    # @param sample_rate [Fixnum] cause +libhoney+ to send 1 out of +sample_rate+ events.
    #   overrides the libhoney instance's value.  (e.g. setting this to +10+ will result in
    #   a 1-in-10 chance of it being successfully emitted to Honeycomb, and the
    #   Honeycomb query engine will interpret it as representative of 10 events)
    # @param api_host [String] defaults to +API_HOST+, override to change the
    #   destination for these Honeycomb events.
    # @param transmission [Class, Object, nil] transport used to actually send events. If nil (the default),
    #   will be initialized with a {TransmissionClient}. If Class--for example, {MockTransmissionClient}--will attempt
    #   to create a new instance of that class with {TransmissionClient}'s usual parameters. If Object, checks
    #   that the instance passed in implements the Transmission interface (responds to :add and :close). If the
    #   check does not succeed, a no-op NullTransmission will be used instead.
    # @param block_on_send [Boolean] if more than pending_work_capacity events are written, block sending further events
    # @param block_on_responses [Boolean] if true, block if there is no thread reading from the response queue
    # @param pending_work_capacity [Fixnum] defaults to 1000. If the queue of
    #   pending events exceeds 1000, this client will start dropping events.
    # @param proxy_config [String, nil] proxy connection information
    #   nil: (default, recommended) connection proxying will be determined from any http_proxy, https_proxy, and no_proxy environment
    #     variables set for the process.
    #   String: the value must be the URI for connecting to a forwarding web proxy. Must be parsable by stdlib URI.
    # rubocop:disable Metrics/ParameterLists
    def initialize(writekey: nil,
                   dataset: nil,
                   sample_rate: 1,
                   api_host: API_HOST,
                   user_agent_addition: nil,
                   transmission: nil,
                   block_on_send: false,
                   block_on_responses: false,
                   max_batch_size: 50,
                   send_frequency: 100,
                   max_concurrent_batches: 10,
                   pending_work_capacity: 1000,
                   proxy_config: nil)
      # rubocop:enable Metrics/ParameterLists
      # check for insanity
      raise 'libhoney:  max_concurrent_batches must be greater than 0' if max_concurrent_batches < 1
      raise 'libhoney:  sample rate must be greater than 0'            if sample_rate < 1

      @builder = Builder.new(self, nil)

      @builder.writekey    = writekey
      @builder.dataset     = get_dataset(dataset, writekey)
      @builder.sample_rate = sample_rate
      @builder.api_host    = api_host

      @user_agent_addition = user_agent_addition

      @block_on_send          = block_on_send
      @block_on_responses     = block_on_responses
      @max_batch_size         = max_batch_size
      @send_frequency         = send_frequency
      @max_concurrent_batches = max_concurrent_batches
      @pending_work_capacity  = pending_work_capacity
      @responses              = SizedQueue.new(2 * @pending_work_capacity)
      @proxy_config           = parse_proxy_config(proxy_config)
      @transmission           = setup_transmission(transmission, writekey, dataset)
    end

    attr_reader :block_on_send, :block_on_responses, :max_batch_size,
                :send_frequency, :max_concurrent_batches,
                :pending_work_capacity, :responses

    def_delegators :@builder, :event, :writekey, :writekey=, :dataset, :dataset=,
                   :sample_rate, :sample_rate=, :api_host, :api_host=, :builder

    # Nuke the queue and wait for inflight requests to complete before returning.
    # If you set drain=false, all queued requests will be dropped on the floor.
    def close(drain = true) # rubocop:disable Style/OptionalBooleanParameter
      return @transmission.close(drain) if @transmission

      0
    end

    # adds a group of field->values to the global Builder.
    #
    # @param data [Hash<String=>any>] field->value mapping.
    # @return [self] this Client instance
    # @example
    #   honey.add {
    #     :responseTime_ms => 100,
    #     :httpStatusCode => 200
    #   }
    def add(data)
      @builder.add(data)
      self
    end

    # adds a single field->value mapping to the global Builder.
    #
    # @param name [String] name of field to add.
    # @param val [any] value of field to add.
    # @return [self] this Client instance
    # @example
    #   honey.add_field("responseTime_ms", 100)
    def add_field(name, val)
      @builder.add_field(name, val)
      self
    end

    # adds a single field->dynamic value function to the global Builder.
    #
    # @param name [String] name of field to add.
    # @param proc [#call] function that will be called to generate the value whenever an event is created.
    # @return [self] this libhoney instance.
    # @example
    #   honey.add_dynamic_field("active_threads", Proc.new { Thread.list.select {|thread| thread.status == "run"}.count })
    def add_dynamic_field(name, proc)
      @builder.add_dynamic_field(name, proc)
      self
    end

    # @deprecated
    # Creates and sends an event, including all global builder fields/dyn_fields, as well as anything in the optional data parameter.
    #
    # Equivalent to:
    #   ev = builder.event
    #   ev.add(data)
    #   ev.send
    #
    # May be removed in a future major release
    #
    # @param data [Hash<String=>any>] optional field->value mapping to add to the event sent.
    # @return [self] this libhoney instance.
    # @example empty send_now
    #   honey.send_now # sends just the data that has been added via add/add_field/add_dynamic_field.
    # @example adding data at send-time
    #   honey.send_now {
    #     additionalField: value
    #   }
    # /
    def send_now(data = {})
      @builder.send_now(data)
      self
    end

    ##
    # Enqueue an event to send.  Sampling happens here, and we will create
    # new threads to handle work as long as we haven't gone over max_concurrent_batches and
    # there are still events in the queue.
    #
    # @param event [Event] the event to send to honeycomb
    # @api private
    def send_event(event)
      @transmission.add(event)
    end

    # @api private
    def send_dropped_response(event, msg)
      response = Response.new(error: msg,
                              metadata: event.metadata)
      begin
        @responses.enq(response, !@block_on_responses)
      rescue ThreadError
        # happens if the queue was full and block_on_responses = false.
      end
    end

    # @api private
    def should_drop(sample_rate)
      rand(1..sample_rate) != 1
    end

    private

    ##
    # Parameters to pass to a transmission based on client config.
    #
    def transmission_client_params
      {
        max_batch_size: @max_batch_size,
        send_frequency: @send_frequency,
        max_concurrent_batches: @max_concurrent_batches,
        pending_work_capacity: @pending_work_capacity,
        responses: @responses,
        block_on_send: @block_on_send,
        block_on_responses: @block_on_responses,
        user_agent_addition: @user_agent_addition,
        proxy_config: @proxy_config
      }
    end

    def setup_transmission(transmission, writekey, dataset)
      # if a provided transmission can add and close, we'll assume the user
      # has provided a working transmission with a customized configuration
      return transmission if quacks_like_a_transmission?(transmission)

      if !(writekey && dataset) # rubocop:disable Style/NegatedIf
        # if no writekey or dataset are configured, and we didn't override the
        # transmission (e.g. to a MockTransmissionClient), that's almost
        # certainly a misconfiguration, even though it's possible to override
        # them on a per-event basis. So let's handle the misconfiguration
        # early rather than potentially throwing thousands of exceptions at runtime.
        warn "#{self.class.name}: no #{writekey ? 'dataset' : 'writekey'} configured, disabling sending events"
        return NullTransmissionClient.new
      end

      case transmission
      # rubocop:disable Style/GuardClause, Style/RedundantReturn
      when NilClass # the default value for new clients
        return TransmissionClient.new(**transmission_client_params)
      when Class
        # if a class has been provided, attempt to instantiate it with parameters given to the client
        t = transmission.new(**transmission_client_params)
        if quacks_like_a_transmission?(t)
          return t
        else
          warn "#{t.class.name}: does not appear to behave like a transmission, disabling sending events"
          return NullTransmissionClient.new
        end
      end
      # rubocop:enable Style/GuardClause, Style/RedundantReturn
    end

    def quacks_like_a_transmission?(transmission)
      transmission.respond_to?(:add) && transmission.respond_to?(:close)
    end

    # @api private
    def parse_proxy_config(config)
      case config
      when nil then nil
      when String
        URI.parse(config)
      when Array
        error_message = <<~MESSAGE
          #{self.class.name}: the optional proxy_config parameter requires a String value; Array is no longer supported.
          To resolve:
            + recommended: set http/https_proxy environment variables, which take precedence over any option set here, then remove proxy_config parameter from client initialization
            + set proxy_config to a String containing the forwarding proxy URI (only used if http/https_proxy environment variables are not set)
        MESSAGE
        raise error_message
      end
    rescue URI::Error => e
      warn "#{self.class.name}: unable to parse proxy_config. Detail: #{e.class}: #{e.message}"
    end

    def get_dataset(dataset, write_key)
      return dataset if classic_write_key?(write_key)

      if dataset.nil? || dataset.empty?
        warn "nil or empty dataset - sending data to '#{DEFAULT_DATASET}'"
        dataset = DEFAULT_DATASET
      end
      trimmed = dataset.strip
      if dataset != trimmed
        warn "dataset contained leading or trailing whitespace - sending data to '#{trimmed}'"
        dataset = trimmed
      end
      dataset
    end

    def classic_write_key?(write_key)
      write_key.nil? || write_key.length == 32
    end
  end
end
