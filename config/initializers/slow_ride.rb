require "redis"
require "slow_ride"

SlowRide.enable_redis do
  Redis.new(url: ENV["REDIS_SLOW_RIDE_URL"] || ENV["REDIS_URL"])
end

# 20% Failure rate
# 100 checks
# Reset after it hasn't been checked in 5 minutes
MY_FEATURE = SlowRide::Redis.new(:my_feature, failure_threshold: 0.2, minimum_checks: 100, max_duration: 5.minutes) do
  Flipper.disable :my_feature
  Rails.logger.warn "Flipper my_feature disabled"
end

# Example usage of SlowRide with Flipper
#
# To test:
#   # Run 80x doing definitely very normal things
#   80.times { check_slow_ride { 123 } }
#   Flipper.enabled?(:my_feature) # => true
#
#   # Run another 25x where it errors out
#   19.times { check_slow_ride { raise "hell" } rescue nil }
#   Flipper.enabled?(:my_feature) # => true, we haven't reached the failure threshold or the min checks yet
#
#   # One more error
#   check_slow_ride { raise "hell" } rescue nil
#   Flipper.enabled?(:my_feature) # => false, automatically disabled
def check_slow_ride(&block)
  if FeatureFlag.enabled?(:my_feature)
    # Feature flag is on
    MY_FEATURE.check(&block)
  else
    # Do the normal thing, which in this case is nothing
  end
end
