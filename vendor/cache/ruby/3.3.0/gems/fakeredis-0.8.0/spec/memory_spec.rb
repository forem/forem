require 'spec_helper'

RSpec.describe FakeRedis do
  let(:redis) { Redis.new }

  def populate_keys_in_redis(num)
    num.times do |count|
      redis.set("key#{count}", count)
    end
  end

  describe '#write' do
    it 'should not send unexpected arguments' do
      expect { redis.write(['info', 'server']) }.not_to raise_error
    end
  end

  describe '#scan' do
    def result
      returned_keys = []
      cursor = 0

      loop do
        cursor, keys = redis.scan(cursor, match_arguments)
        returned_keys += keys
        break if cursor == '0'
      end
      returned_keys
    end

    before do
      populate_keys_in_redis(11)
    end

    context('when deleting') do
      it('preverves cursor') do
        cursor, keys = redis.scan('0')
        keys.each { |key| redis.del(key) }
        _, keys = redis.scan(cursor)
        expect(keys).to eq(%w(key10))
      end
    end

    context 'with one namespace' do
      let(:match_arguments) { {} }

      it 'returns the expected array of keys' do
        expect(result).to match_array(redis.keys)
      end
    end

    context 'with multiple namespaces' do
      let(:namespaced_key) { 'test' }
      let(:match_arguments) { { match: namespaced_key } }

      before { redis.set(namespaced_key, 12) }

      it 'returns the expected array of keys' do
        expect(result).to match_array([namespaced_key])
      end
    end
  end

  describe 'time' do
    before(:each) do
      allow(Time).to receive_message_chain(:now, :to_f).and_return(1397845595.5139461)
    end

    it 'is an array' do
      expect(redis.time).to be_an_instance_of(Array)
    end

    it 'has two elements' do
      expect(redis.time.count).to eql 2
    end

    if fakeredis?
      it 'has the current time in seconds' do
        expect(redis.time.first).to eql 1397845595
      end

      it 'has the current leftover microseconds' do
        expect(redis.time.last).to eql 513946
      end
    end
  end

  describe '#client' do
    it 'returns OK when command is :setname' do
      expect(redis.client(:setname, 'my-client-01')).to eq 'OK'
    end

    it 'returns nil when command is :getname' do
      expect(redis.client(:getname)).to eq nil
    end

    it 'raises error for other commands' do
      expect { redis.write([:client, :wrong]) }.to raise_error(Redis::CommandError, "ERR unknown command 'wrong'")
    end
  end
end
