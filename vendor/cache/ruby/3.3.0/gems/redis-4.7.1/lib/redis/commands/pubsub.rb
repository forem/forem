# frozen_string_literal: true

class Redis
  module Commands
    module Pubsub
      # Post a message to a channel.
      def publish(channel, message)
        send_command([:publish, channel, message])
      end

      def subscribed?
        synchronize do |client|
          client.is_a? SubscribedClient
        end
      end

      # Listen for messages published to the given channels.
      def subscribe(*channels, &block)
        synchronize do |_client|
          _subscription(:subscribe, 0, channels, block)
        end
      end

      # Listen for messages published to the given channels. Throw a timeout error
      # if there is no messages for a timeout period.
      def subscribe_with_timeout(timeout, *channels, &block)
        synchronize do |_client|
          _subscription(:subscribe_with_timeout, timeout, channels, block)
        end
      end

      # Stop listening for messages posted to the given channels.
      def unsubscribe(*channels)
        synchronize do |client|
          raise "Can't unsubscribe if not subscribed." unless subscribed?

          client.unsubscribe(*channels)
        end
      end

      # Listen for messages published to channels matching the given patterns.
      def psubscribe(*channels, &block)
        synchronize do |_client|
          _subscription(:psubscribe, 0, channels, block)
        end
      end

      # Listen for messages published to channels matching the given patterns.
      # Throw a timeout error if there is no messages for a timeout period.
      def psubscribe_with_timeout(timeout, *channels, &block)
        synchronize do |_client|
          _subscription(:psubscribe_with_timeout, timeout, channels, block)
        end
      end

      # Stop listening for messages posted to channels matching the given patterns.
      def punsubscribe(*channels)
        synchronize do |client|
          raise "Can't unsubscribe if not subscribed." unless subscribed?

          client.punsubscribe(*channels)
        end
      end

      # Inspect the state of the Pub/Sub subsystem.
      # Possible subcommands: channels, numsub, numpat.
      def pubsub(subcommand, *args)
        send_command([:pubsub, subcommand] + args)
      end
    end
  end
end
