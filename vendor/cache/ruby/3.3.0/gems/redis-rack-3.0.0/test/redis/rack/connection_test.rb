require 'test_helper'
require 'connection_pool'
require 'redis/rack/connection'

class Redis
  module Rack
    describe Connection do
      def setup
        @defaults = {
          host: 'localhost'
        }
      end

      it "can create it's own pool" do
        conn = Connection.new @defaults.merge(pool_size: 5, pool_timeout: 10)

        conn.pooled?.must_equal true
        conn.pool.class.must_equal ConnectionPool
        conn.pool.instance_variable_get(:@size).must_equal 5
      end

      it "can create it's own pool using default Redis server" do
        conn = Connection.new @defaults.merge(pool_size: 5, pool_timeout: 10)

        conn.pooled?.must_equal true

        conn.with do |connection|
          connection.to_s.must_match(/127\.0\.0\.1:6379 against DB 0$/)
        end
      end

      it "can create it's own pool using provided Redis server" do
        conn = Connection.new(redis_server: 'redis://127.0.0.1:6380/1', pool_size: 5, pool_timeout: 10)
        conn.pooled?.must_equal true
        conn.with do |connection|
          connection.to_s.must_match(/127\.0\.0\.1:6380 against DB 1$/)
        end
      end

      it "can use a supplied pool" do
        pool = ConnectionPool.new size: 1, timeout: 1 do
          ::Redis::Store::Factory.create('redis://127.0.0.1:6380/1')
        end
        conn = Connection.new pool: pool
        conn.pooled?.must_equal true
        conn.pool.class.must_equal ConnectionPool
        conn.pool.instance_variable_get(:@size).must_equal 1
      end

      it "uses the specified Redis store when provided" do
        store = ::Redis::Store::Factory.create('redis://127.0.0.1:6380/1')
        conn = Connection.new(redis_store: store)

        conn.pooled?.must_equal false
        conn.store.to_s.must_match(/127\.0\.0\.1:6380 against DB 1$/)
        conn.store.must_equal(store)
      end

      it "throws an error when provided Redis store is not the expected type" do
        assert_raises ArgumentError do
          Connection.new(redis_store: ::Redis.new)
        end
      end

      it "uses the specified Redis server when provided" do
        conn = Connection.new(redis_server: 'redis://127.0.0.1:6380/1')

        conn.pooled?.must_equal false
        conn.store.to_s.must_match(/127\.0\.0\.1:6380 against DB 1$/)
      end

      it "does not include nil options for the connection pool" do
        conn = Connection.new
        conn.pool_options.must_be_empty

        conn = Connection.new(pool_size: nil)
        conn.pool_options.must_be_empty

        conn = Connection.new(pool_timeout: nil)
        conn.pool_options.must_be_empty
      end
    end
  end
end
