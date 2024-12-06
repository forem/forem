module Libhoney
  # This is the event object that you can fill up with data.
  #
  # @example Override the default timestamp on an event
  #   evt = libhoney.event
  #   evt.add_fields(useful_fields)
  #   evt.timestamp = Time.now
  #   evt.send
  #
  class Event
    # @return [String] the Honeycomb API key with which to authenticate this
    #   request
    attr_accessor :writekey

    # @return [String] the Honeycomb dataset this event is destined for
    #   (defaults to the +Builder+'s +dataset+, which in turn defaults to the
    #   +Client+'s +dataset+)
    attr_accessor :dataset

    # @return [Fixnum] Set this attribute to indicate that it represents
    #   +sample_rate+ number of events (e.g. setting this to +10+ will result in
    #   a 1-in-10 chance of it being successfully emitted to Honeycomb, and the
    #   Honeycomb query engine will interpret it as representative of 10 events)
    attr_accessor :sample_rate

    # @return [String] Set this attribute in order to override the destination
    #   of these Honeycomb events (defaults to +Client::API_HOST+).
    attr_accessor :api_host

    # @return [Object] Set this attribute to any +Object+ you might need to
    #   identify this Event as it is returned to the responses queue (e.g. tag
    #   an Event with an internal ID in order to retry something specific on
    #   failure).
    attr_accessor :metadata

    # @return [Time] Set this attribute in order to override the timestamp
    #   associated with the event (defaults to the +Time.now+ at +Event+
    #   creation)
    attr_accessor :timestamp

    # @return [Hash<String=>any>] the fields added to this event
    attr_reader :data

    # @api private
    # @see Client#event
    # @see Builder#event
    def initialize(libhoney, builder, fields = {}, dyn_fields = {})
      @libhoney    = libhoney
      @writekey    = builder.writekey
      @dataset     = builder.dataset
      @sample_rate = builder.sample_rate
      @api_host    = builder.api_host
      @timestamp   = Time.now
      @metadata    = nil

      @data = {}
      fields.each { |k, v| add_field(k, v) }
      dyn_fields.each { |k, v| add_field(k, v.call) }
    end

    # adds a group of field->values to this event.
    #
    # @param newdata [Hash<String=>any>] field->value mapping.
    # @return [self] this event.
    # @example using an object
    #   builder.event
    #     .add({
    #       :responseTime_ms => 100,
    #       :httpStatusCode => 200
    #     })
    def add(newdata)
      @data.merge!(newdata)
      self
    end

    # adds a single field->value mapping to this event.
    #
    # @param name [String]
    # @param val [any]
    # @return [self] this event.
    # @example
    #   builder.event
    #     .add_field("responseTime_ms", 100)
    #     .send
    def add_field(name, val)
      @data[name] = val
      self
    end

    # times the execution of a block and adds a field containing the duration in milliseconds
    #
    # @param name [String] the name of the field to add to the event
    # @return [self] this event.
    # @example
    #   event.with_timer "task_ms" do
    #     # something time consuming
    #   end
    def with_timer(name)
      start = Time.now
      yield
      duration = Time.now - start
      # report in ms
      add_field(name, duration * 1000)
      self
    end

    # sends this event to Honeycomb
    #
    # @return [self] this event.
    def send
      # discard if sampling rate says so
      if @libhoney.should_drop(sample_rate)
        @libhoney.send_dropped_response(self, 'event dropped due to sampling')
        return
      end

      send_presampled
    end

    # sends a presampled event to Honeycomb
    #
    # @return [self] this event.
    def send_presampled
      @libhoney.send_event(self)
      self
    end
  end
end
