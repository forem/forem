require 'spec_helper'

module FakeRedis
  describe "#bitop" do
    before(:all) do
      @client = Redis.new
    end

    before(:each) do
      @client.discard rescue nil
    end

    it 'raises an argument error when passed unsupported operation' do
      expect { @client.bitop("meh", "dest1", "key1") }.to raise_error(Redis::CommandError)
    end

    describe "or" do
      it_should_behave_like "a bitwise operation", "or"

      it "should apply bitwise or operation" do
        @client.setbit("key1", 0, 0)
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 1)
        @client.setbit("key1", 3, 0)

        @client.setbit("key2", 0, 1)
        @client.setbit("key2", 1, 1)
        @client.setbit("key2", 2, 0)
        @client.setbit("key2", 3, 0)

        expect(@client.bitop("or", "dest1", "key1", "key2")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(3)
        expect(@client.getbit("dest1", 0)).to eq(1)
        expect(@client.getbit("dest1", 1)).to eq(1)
        expect(@client.getbit("dest1", 2)).to eq(1)
        expect(@client.getbit("dest1", 3)).to eq(0)
      end

      it "should apply bitwise or operation with empty values" do
        @client.setbit("key1", 1, 1)

        expect(@client.bitop("or", "dest1", "key1", "nothing_here1", "nothing_here2")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(1)
        expect(@client.getbit("dest1", 0)).to eq(0)
        expect(@client.getbit("dest1", 1)).to eq(1)
        expect(@client.getbit("dest1", 2)).to eq(0)
      end

      it "should apply bitwise or operation with multiple keys" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 3, 1)

        @client.setbit("key2", 5, 1)
        @client.setbit("key2", 10, 1)

        @client.setbit("key3", 13, 1)
        @client.setbit("key3", 15, 1)

        expect(@client.bitop("or", "dest1", "key1", "key2", "key3")).to eq(2)
        expect(@client.bitcount("dest1")).to eq(6)
        expect(@client.getbit("dest1", 1)).to eq(1)
        expect(@client.getbit("dest1", 3)).to eq(1)
        expect(@client.getbit("dest1", 5)).to eq(1)
        expect(@client.getbit("dest1", 10)).to eq(1)
        expect(@client.getbit("dest1", 13)).to eq(1)
        expect(@client.getbit("dest1", 15)).to eq(1)
        expect(@client.getbit("dest1", 2)).to eq(0)
        expect(@client.getbit("dest1", 12)).to eq(0)
      end
    end

    describe "and" do
      it_should_behave_like "a bitwise operation", "and"

      it "should apply bitwise and operation" do
        @client.setbit("key1", 0, 1)
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 0)

        @client.setbit("key2", 0, 0)
        @client.setbit("key2", 1, 1)
        @client.setbit("key2", 2, 1)

        expect(@client.bitop("and", "dest1", "key1", "key2")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(1)
        expect(@client.getbit("dest1", 0)).to eq(0)
        expect(@client.getbit("dest1", 1)).to eq(1)
        expect(@client.getbit("dest1", 2)).to eq(0)
      end

      it "should apply bitwise and operation with empty values" do
        @client.setbit("key1", 1, 1)

        expect(@client.bitop("and", "dest1", "key1", "nothing_here")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(1)
        expect(@client.getbit("dest1", 0)).to eq(0)
        expect(@client.getbit("dest1", 1)).to eq(1)
        expect(@client.getbit("dest1", 2)).to eq(0)
      end

      it "should apply bitwise and operation with multiple keys" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 1)
        @client.setbit("key1", 3, 1)
        @client.setbit("key1", 4, 1)

        @client.setbit("key2", 2, 1)
        @client.setbit("key2", 3, 1)
        @client.setbit("key2", 4, 1)
        @client.setbit("key2", 5, 1)

        @client.setbit("key3", 2, 1)
        @client.setbit("key3", 4, 1)
        @client.setbit("key3", 5, 1)
        @client.setbit("key3", 6, 1)

        expect(@client.bitop("and", "dest1", "key1", "key2", "key3")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(2)
        expect(@client.getbit("dest1", 1)).to eq(0)
        expect(@client.getbit("dest1", 2)).to eq(1)
        expect(@client.getbit("dest1", 3)).to eq(0)
        expect(@client.getbit("dest1", 4)).to eq(1)
        expect(@client.getbit("dest1", 5)).to eq(0)
        expect(@client.getbit("dest1", 6)).to eq(0)
      end
    end

    describe "xor" do
      it_should_behave_like "a bitwise operation", "xor"

      it "should apply bitwise xor operation" do
        @client.setbit("key1", 0, 0)
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 0)
        @client.setbit("key1", 3, 0)

        @client.setbit("key2", 0, 1)
        @client.setbit("key2", 1, 1)
        @client.setbit("key2", 2, 1)
        @client.setbit("key2", 3, 0)

        expect(@client.bitop("xor", "dest1", "key1", "key2")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(2)
        expect(@client.getbit("dest1", 0)).to eq(1)
        expect(@client.getbit("dest1", 1)).to eq(0)
        expect(@client.getbit("dest1", 2)).to eq(1)
        expect(@client.getbit("dest1", 3)).to eq(0)
      end

      it "should apply bitwise xor operation with empty values" do
        @client.setbit("key1", 1, 1)

        expect(@client.bitop("xor", "dest1", "key1", "nothing_here1", "nothing_here2")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(1)
        expect(@client.getbit("dest1", 0)).to eq(0)
        expect(@client.getbit("dest1", 1)).to eq(1)
        expect(@client.getbit("dest1", 2)).to eq(0)
      end

      it "should apply bitwise xor operation with multiple keys" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 3, 1)
        @client.setbit("key1", 5, 1)
        @client.setbit("key1", 6, 1)

        @client.setbit("key2", 2, 1)
        @client.setbit("key2", 3, 1)
        @client.setbit("key2", 4, 1)
        @client.setbit("key2", 6, 1)

        expect(@client.bitop("xor", "dest1", "key1", "key2")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(4)
        expect(@client.getbit("dest1", 1)).to eq(1)
        expect(@client.getbit("dest1", 2)).to eq(1)
        expect(@client.getbit("dest1", 3)).to eq(0)
        expect(@client.getbit("dest1", 4)).to eq(1)
        expect(@client.getbit("dest1", 5)).to eq(1)
        expect(@client.getbit("dest1", 6)).to eq(0)
      end
    end

    describe "not" do
      it 'raises an argument error when not passed any keys' do
        expect { @client.bitop("not", "destkey") }.to raise_error(Redis::CommandError)
      end

      it 'raises an argument error when not passed too many keys' do
        expect { @client.bitop("not", "destkey", "key1", "key2") }.to raise_error(Redis::CommandError)
      end

      it "should apply bitwise negation operation" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 3, 1)
        @client.setbit("key1", 5, 1)

        expect(@client.bitop("not", "dest1", "key1")).to eq(1)
        expect(@client.bitcount("dest1")).to eq(5)
        expect(@client.getbit("dest1", 0)).to eq(1)
        expect(@client.getbit("dest1", 1)).to eq(0)
        expect(@client.getbit("dest1", 2)).to eq(1)
        expect(@client.getbit("dest1", 3)).to eq(0)
        expect(@client.getbit("dest1", 4)).to eq(1)
        expect(@client.getbit("dest1", 5)).to eq(0)
        expect(@client.getbit("dest1", 6)).to eq(1)
        expect(@client.getbit("dest1", 7)).to eq(1)
      end
    end
  end
end
