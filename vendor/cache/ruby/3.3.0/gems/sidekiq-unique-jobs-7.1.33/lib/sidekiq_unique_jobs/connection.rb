# frozen_string_literal: true

module SidekiqUniqueJobs
  # Shared module for dealing with redis connections
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Connection
    def self.included(base)
      base.send(:extend, self)
    end

    # Creates a connection to redis
    # @return [Sidekiq::RedisConnection, ConnectionPool] a connection to redis
    def redis(r_pool = nil, &block)
      r_pool ||= defined?(redis_pool) ? redis_pool : r_pool
      if r_pool
        r_pool.with(&block)
      else
        Sidekiq.redis(&block)
      end
    end
  end
end
