# frozen_string_literal: true

require_relative 'address_hash'
require_relative 'subscriber'

module Datadog
  module AppSec
    module Reactive
      # Reactive Engine
      class Engine
        def initialize
          @data = {}
          @subscribers = AddressHash.new
        end

        def subscribe(*addresses, &block)
          @subscribers[addresses.freeze] << Subscriber.new(&block)
        end

        def publish(address, value)
          # check if someone has address subscribed
          if @subscribers.addresses.include?(address)

            # someone will be interested, set value
            @data[address] = value

            # find candidates i.e address groups that contain the just posted address
            @subscribers.with(address).each do |addresses|
              # find targets to the address group containing the posted address
              subscribers = @subscribers[addresses]

              # is all data for the targets available?
              if (addresses - @data.keys).empty?
                hash = addresses.each_with_object({}) { |a, h| h[a] = @data[a] }
                subscribers.each { |s| s.call(*hash.values) }
              end
            end
          end
        end

        private

        attr_reader :subscribers, :data
      end
    end
  end
end
