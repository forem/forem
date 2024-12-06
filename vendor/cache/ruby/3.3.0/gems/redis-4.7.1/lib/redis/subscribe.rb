# frozen_string_literal: true

class Redis
  class SubscribedClient
    def initialize(client)
      @client = client
    end

    def call(command)
      @client.process([command])
    end

    def subscribe(*channels, &block)
      subscription("subscribe", "unsubscribe", channels, block)
    end

    def subscribe_with_timeout(timeout, *channels, &block)
      subscription("subscribe", "unsubscribe", channels, block, timeout)
    end

    def psubscribe(*channels, &block)
      subscription("psubscribe", "punsubscribe", channels, block)
    end

    def psubscribe_with_timeout(timeout, *channels, &block)
      subscription("psubscribe", "punsubscribe", channels, block, timeout)
    end

    def unsubscribe(*channels)
      call([:unsubscribe, *channels])
    end

    def punsubscribe(*channels)
      call([:punsubscribe, *channels])
    end

    protected

    def subscription(start, stop, channels, block, timeout = 0)
      sub = Subscription.new(&block)

      unsubscribed = false

      @client.call_loop([start, *channels], timeout) do |line|
        type, *rest = line
        sub.callbacks[type].call(*rest)
        unsubscribed = type == stop && rest.last == 0
        break if unsubscribed
      end
      # No need to unsubscribe here. The real client closes the connection
      # whenever an exception is raised (see #ensure_connected).
    end
  end

  class Subscription
    attr :callbacks

    def initialize
      @callbacks = Hash.new do |hash, key|
        hash[key] = ->(*_) {}
      end

      yield(self)
    end

    def subscribe(&block)
      @callbacks["subscribe"] = block
    end

    def unsubscribe(&block)
      @callbacks["unsubscribe"] = block
    end

    def message(&block)
      @callbacks["message"] = block
    end

    def psubscribe(&block)
      @callbacks["psubscribe"] = block
    end

    def punsubscribe(&block)
      @callbacks["punsubscribe"] = block
    end

    def pmessage(&block)
      @callbacks["pmessage"] = block
    end
  end
end
