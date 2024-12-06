require 'securerandom'
require 'active_support/notifications'
require 'flipper/instrumentation/statsd_subscriber'

ActiveSupport::Notifications.subscribe /\.flipper$/,
                                       Flipper::Instrumentation::StatsdSubscriber
