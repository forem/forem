require 'spec_helper'

module FakeRedis
  describe "Compatibility" do
    it "should be accessible through FakeRedis::Redis" do
      expect { FakeRedis::Redis.new }.not_to raise_error
    end
  end
end
