require 'libhoney/event'

module Libhoney
  class Builder
    attr_accessor :writekey, :dataset, :sample_rate, :api_host, :fields, :dyn_fields

    # @api private
    # @see Client#builder
    # @see Builder#builder
    def initialize(libhoney, parent_builder, fields = {}, dyn_fields = {})
      @libhoney = libhoney

      @fields     = {}
      @dyn_fields = {}

      unless parent_builder.nil?
        @writekey    = parent_builder.writekey
        @dataset     = parent_builder.dataset
        @sample_rate = parent_builder.sample_rate
        @api_host    = parent_builder.api_host

        @fields.merge!(parent_builder.fields)
        @dyn_fields.merge!(parent_builder.dyn_fields)
      end

      @fields.merge!(fields)
      @dyn_fields.merge!(dyn_fields)
    end

    # adds a group of field->values to the events created from this builder.
    #
    # @param data [Hash<String=>any>] field->value mapping.
    # @return [self] this Builder instance.
    # @example using an object
    #   honey = Libhoney::Client.new(...)
    #   builder = honey.builder
    #   builder.add {
    #     :responseTime_ms => 100,
    #     :httpStatusCode => 200
    #   }
    def add(data)
      @fields.merge!(data)
      self
    end

    # adds a single field->value mapping to the events created from this builder.
    #
    # @param name [string]
    # @param val [any]
    # @return [self] this Builder instance.
    # @example
    #   builder.add_field("responseTime_ms", 100)
    def add_field(name, val)
      @fields[name] = val
      self
    end

    # adds a single field->dynamic value function, which is invoked to supply values when events are created from this builder.
    #
    # @param name [string] the name of the field to add to events.
    # @param proc [#call] the function called to generate the value for this field.
    # @return [self] this Builder instance.
    # @example
    #   builder.add_dynamic_field("process_heapUsed", Proc.new { Thread.list.select {|thread| thread.status == "run"}.count })
    def add_dynamic_field(name, proc)
      @dyn_fields[name] = proc
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
    # @return [self] this Builder instance
    # @example empty send_now
    #   builder.send_now # sends just the data that has been added via add/add_field/add_dynamic_field.
    # @example adding data at send-time
    #   builder.send_now {
    #     :additionalField => value
    #   }
    def send_now(data = {})
      ev = event
      ev.add(data)
      ev.send
      self
    end

    # creates and returns a new Event containing all fields/dyn_fields from this builder, that can be further fleshed out and sent on its own.
    #
    # @return [Event] an Event instance
    # @example adding data at send-time
    #   ev = builder.event
    #   ev.add_field("additionalField", value)
    #   ev.send
    def event
      Event.new(@libhoney, self, @fields, @dyn_fields)
    end

    # creates and returns a clone of this builder, merged with fields and dyn_fields passed as arguments.
    #
    # @param fields [Hash<String=>any>] a field->value mapping to merge into the new builder.
    # @param dyn_fields [Hash<String=>#call>] a field->dynamic function mapping to merge into the new builder.
    # @return [Builder] a Builder instance
    # @example no additional fields/dyn_field
    #   another_builder = the_builder.builder
    # @example additional fields/dyn_field
    #   anotherBuilder = the_builder.builder({ :request_id => @request_id },
    #                                        { :active_threads => Proc.new { Thread.list.select {|thread| thread.status == "run"}.count } });
    def builder(fields = {}, dyn_fields = {})
      Builder.new(@libhoney, self, fields, dyn_fields)
    end
  end
end
