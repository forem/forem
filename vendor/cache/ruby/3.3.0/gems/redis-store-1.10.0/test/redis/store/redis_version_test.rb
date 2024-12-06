require 'test_helper'

describe "Redis::RedisVersion" do
  def setup
    @store = Redis::Store.new
  end

  def teardown
    @store.quit
  end

  describe '#redis_version' do
    it 'returns redis version' do
      _(@store.redis_version.to_s).must_match(/^\d{1}\.\d{1,}\.\d{1,}$/)
    end
  end

  describe '#supports_redis_version?' do
    it 'returns true if redis version is greater or equal to required version' do
      @store.stubs(:redis_version).returns('2.8.19')
      _(@store.supports_redis_version?('2.6.0')).must_equal(true)
      _(@store.supports_redis_version?('2.8.19')).must_equal(true)
      _(@store.supports_redis_version?('2.8.20')).must_equal(false)
      _(@store.supports_redis_version?('2.9.0')).must_equal(false)
      _(@store.supports_redis_version?('3.0.0')).must_equal(false)
    end
  end
end
