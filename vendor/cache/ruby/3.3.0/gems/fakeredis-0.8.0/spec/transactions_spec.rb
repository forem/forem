require 'spec_helper'

module FakeRedis
  describe "TransactionsMethods" do
    before(:all) do
      @client = Redis.new
    end

    before(:each) do
      @client.discard rescue nil
    end

    context '#multi' do
      it "should respond with 'OK'" do
        expect(@client.multi).to eq('OK')
      end

      it "should forbid nesting" do
        @client.multi
        expect{@client.multi}.to raise_error(Redis::CommandError)
      end

      it "should mark the start of a transaction block" do
        transaction = @client.multi do |multi|
          multi.set("key1", "1")
          multi.set("key2", "2")
          multi.expire("key1", 123)
          multi.mget("key1", "key2")
        end

        expect(transaction).to eq(["OK", "OK", true, ["1", "2"]])
      end
    end

    context '#discard' do
      it "should respond with 'OK' after #multi" do
        @client.multi
        expect(@client.discard).to eq('OK')
      end

      it "can't be run outside of #multi/#exec" do
        expect{@client.discard}.to raise_error(Redis::CommandError)
      end
    end

    context '#exec' do
      it "can't be run outside of #multi" do
        expect{@client.exec}.to raise_error(Redis::CommandError)
      end
    end

    context 'saving up commands for later' do
      before(:each) do
        @client.multi
        @string = 'fake-redis-test:string'
        @list = 'fake-redis-test:list'
      end

      it "makes commands respond with 'QUEUED'" do
        expect(@client.set(@string, 'string')).to eq('QUEUED')
        expect(@client.lpush(@list, 'list')).to eq('QUEUED')
      end

      it "gives you the commands' responses when you call #exec" do
        @client.set(@string, 'string')
        @client.lpush(@list, 'list')
        @client.lpush(@list, 'list')

        expect(@client.exec).to eq(['OK', 1, 2])
      end

      it "does not raise exceptions, but rather puts them in #exec's response" do
        @client.set(@string, 'string')
        @client.lpush(@string, 'oops!')
        @client.lpush(@list, 'list')

        responses = @client.exec
        expect(responses[0]).to eq('OK')
        expect(responses[1]).to be_a(RuntimeError)
        expect(responses[2]).to eq(1)
      end
    end

    context 'executing hash commands in a block' do
      it "returns true if the nested hash command succeeds" do
        responses = @client.multi { |multi| multi.hset('hash', 'key', 'value') }

        expect(responses[0]).to eq(true)
      end
    end

    context 'executing set commands in a block' do
      it "returns commands' responses for nested commands" do
        @client.sadd('set', 'member1')

        responses = @client.multi do |multi|
          multi.sadd('set', 'member1')
          multi.sadd('set', 'member2')
        end

        expect(responses).to eq([false, true])
      end
    end
  end
end
