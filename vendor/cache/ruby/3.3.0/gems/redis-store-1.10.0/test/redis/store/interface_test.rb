require 'test_helper'

class InterfacedRedis < Redis
  include Redis::Store::Interface
end

describe Redis::Store::Interface do
  before do
    @r = InterfacedRedis.new
  end

  it "should get an element" do
    lambda { @r.get("key", :option => true) } # .wont_raise ArgumentError
  end

  it "should set an element" do
    lambda { @r.set("key", "value", :option => true) } # .wont_raise ArgumentError
  end

  it "should setnx an element" do
    lambda { @r.setnx("key", "value", :option => true) } # .wont_raise ArgumentError
  end

  it "should setex an element" do
    lambda { @r.setex("key", 1, "value", :option => true) } # .wont_raise ArgumentError
  end
end
