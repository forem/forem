require 'bundler/setup'
require_relative 'active_record/ar_setup'
require 'flipper'
require 'flipper/adapters/redis'
require 'flipper/adapters/active_record'

# Say you are using redis...
redis_adapter = Flipper::Adapters::Redis.new(Redis.new)
redis_flipper = Flipper.new(redis_adapter)

# And redis has some stuff enabled...
redis_flipper.enable(:search)
redis_flipper.enable_percentage_of_time(:verbose_logging, 5)
redis_flipper.enable_percentage_of_actors(:new_feature, 5)
redis_flipper.enable_actor(:issues, Flipper::Actor.new('1'))
redis_flipper.enable_actor(:issues, Flipper::Actor.new('2'))
redis_flipper.enable_group(:request_tracing, :staff)

# And you would like to switch to active record...
ar_adapter = Flipper::Adapters::ActiveRecord.new
ar_flipper = Flipper.new(ar_adapter)

# NOTE: This wipes active record clean and copies features/gates from redis into active record.
ar_flipper.import(redis_flipper)

# active record is now identical to redis.
ar_flipper.features.each do |feature|
  pp feature: feature.key, values: feature.gate_values
end
