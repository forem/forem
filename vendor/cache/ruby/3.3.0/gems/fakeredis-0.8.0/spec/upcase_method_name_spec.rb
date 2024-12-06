require 'spec_helper'

module FakeRedis
  describe "UPCASE method name will call downcase method" do

    before do
      @client = Redis.new
    end

    it "#ZCOUNT" do
      expect(@client.ZCOUNT("key", 2, 3)).to eq(@client.zcount("key", 2, 3))
    end

    it "#ZSCORE" do
      expect(@client.ZSCORE("key", 2)).to eq(@client.zscore("key", 2))
    end
  end
end
