require 'test_helper'

describe Redis::Store do
  def setup
    @store  = Redis::Store.new
    @client = @store.instance_variable_get(:@client)
  end

  def teardown
    @store.flushdb
    @store.quit
  end

  it "returns useful informations about the server" do
    _(@store.to_s).must_equal("Redis Client connected to #{@client.host}:#{@client.port} against DB #{@client.db}")
  end

  it "must force reconnection" do
    @client.expects(:reconnect)
    @store.reconnect
  end

  describe '#set' do
    describe 'with expiry' do
      let(:options) { { :expire_after => 3600 } }

      it 'must not double marshall' do
        Marshal.expects(:dump).once

        @store.set('key', 'value', options)
      end
    end

    describe 'with ex and nx' do
      let(:key) { 'key' }
      let(:mock_value) { 'value' }
      let(:options) { { nx: true, ex: 3600 } }

      it 'must pass on options' do
        Marshal.expects(:dump).times(4)

        # without options no ex or nx will be set
        @store.del(key)
        _(@store.set(key, mock_value, {})).must_equal 'OK'
        _(@store.set(key, mock_value, {})).must_equal 'OK'
        _(@store.ttl(key)).must_equal(-1)

        # with ex and nx options, the key can only be set once and a ttl will be set
        @store.del(key)
        _(@store.set(key, mock_value, options)).must_equal true
        _(@store.set(key, mock_value, options)).must_equal false
        _(@store.ttl(key)).must_equal 3600
      end
    end
  end

  describe '#setnx' do
    describe 'with expiry' do
      let(:options) { { :expire_after => 3600 } }

      it 'must not double marshall' do
        Marshal.expects(:dump).once

        @store.setnx('key', 'value', options)
      end
    end
  end
end
