# Quick example of how to keep track of when a feature was last checked.
require 'bundler/setup'
require 'securerandom'
require 'active_support/isolated_execution_state'
require 'active_support/notifications'
require 'flipper'

class FlipperSubscriber
  def self.stats
    @stats ||= {}
  end

  def call(name, start, finish, id, payload)
    if payload[:operation] == :enabled?
      feature_name = payload.fetch(:feature_name)
      self.class.stats[feature_name] = Time.now
    end
  end

  ActiveSupport::Notifications.subscribe(/feature_operation.flipper/, new)
end

Flipper.configure do |config|
  config.default {
    Flipper.new(config.adapter, instrumenter: ActiveSupport::Notifications)
  }
end

Flipper.enabled?(:search)
Flipper.enabled?(:booyeah)
Flipper.enabled?(:hooray)
sleep 1
Flipper.enabled?(:booyeah)
Flipper.enabled?(:hooray)
sleep 1
Flipper.enabled?(:hooray)

pp FlipperSubscriber.stats
