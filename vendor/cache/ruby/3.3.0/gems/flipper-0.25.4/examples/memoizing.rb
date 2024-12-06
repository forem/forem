require 'bundler/setup'
require 'flipper'
require 'flipper/adapters/operation_logger'
require 'flipper/instrumentation/log_subscriber'

Flipper.configure do |config|
  config.adapter do
    # pick an adapter, this uses memory, any will do
    Flipper::Adapters::OperationLogger.new(Flipper::Adapters::Memory.new)
  end
end

Flipper.enable(:foo)
Flipper.enable(:bar)
Flipper.disable(:baz)
Flipper.disable(:wick)
# reset the operation logging adapter to empty for clarity
Flipper.adapter.reset

# Turn on memoization (the memoizing middleware does this per request).
Flipper.memoize = true

# Preload all the features.
Flipper.preload_all

# Do as many feature checks as your heart desires.
%w[foo bar baz wick].each do |name|
  Flipper.enabled?(name)
end

# See that only one operation exists, a get_all (which is the preload_all).
pp Flipper.adapter.operations
# [#<Flipper::Adapters::OperationLogger::Operation:0x00007fdcfe1100e8
#   @args=[],
#   @type=:get_all>]
