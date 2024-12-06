require 'test_helper'

describe "Redis::DistributedStore" do
  def setup
    @dmr = Redis::DistributedStore.new [
      { :host => "localhost", :port => "6380", :db => 0 },
      { :host => "localhost", :port => "6381", :db => 0 }
    ]
    @rabbit = OpenStruct.new :name => "bunny"
    @white_rabbit = OpenStruct.new :color => "white"
    @dmr.set "rabbit", @rabbit
  end

  def teardown
    @dmr.ring.nodes.each { |server| server.flushdb }
  end

  it "accepts connection params" do
    dmr = Redis::DistributedStore.new [ :host => "localhost", :port => "6380", :db => "1" ]
    _(dmr.ring.nodes.size).must_equal(1)
    mr = dmr.ring.nodes.first
    _(mr.to_s).must_equal("Redis Client connected to localhost:6380 against DB 1")
  end

  it "forces reconnection" do
    @dmr.nodes.each do |node|
      node.expects(:reconnect)
    end

    @dmr.reconnect
  end

  it "sets an object" do
    @dmr.set "rabbit", @white_rabbit
    _(@dmr.get("rabbit")).must_equal(@white_rabbit)
  end

  it "gets an object" do
    _(@dmr.get("rabbit")).must_equal(@rabbit)
  end

  it "mget" do
    @dmr.set "rabbit2", @white_rabbit
    begin
      @dmr.mget "rabbit", "rabbit2" do |rabbits|
        rabbit, rabbit2 = rabbits
        _(rabbits.length).must_equal(2)
        _(rabbit).must_equal(@rabbit)
        _(rabbit2).must_equal(@white_rabbit)
      end
    rescue Redis::Distributed::CannotDistribute
      # Not supported on redis-rb < 4, and hence Ruby < 2.2.
    end
  end

  it "mapped_mget" do
    @dmr.set "rabbit2", @white_rabbit
    begin
      result = @dmr.mapped_mget("rabbit", "rabbit2")
      _(result.keys).must_equal %w[ rabbit rabbit2 ]
      _(result["rabbit"]).must_equal @rabbit
      _(result["rabbit2"]).must_equal @white_rabbit
    rescue Redis::Distributed::CannotDistribute
      # Not supported on redis-rb < 4, and hence Ruby < 2.2.
    end
  end

  it "passes through ring replica options" do
    dmr = Redis::DistributedStore.new [
                                    { :host => "localhost", :port => "6380", :db => 0 },
                                    { :host => "localhost", :port => "6381", :db => 0 }
                                ], replicas: 1024
    _(dmr.ring.replicas).must_equal 1024
  end

  it "uses a custom ring object" do
    my_ring = Redis::HashRing.new
    dmr = Redis::DistributedStore.new [
                                          { :host => "localhost", :port => "6380", :db => 0 },
                                          { :host => "localhost", :port => "6381", :db => 0 }
                                      ], ring: my_ring
    _(dmr.ring).must_equal my_ring
    _(dmr.ring.nodes.length).must_equal 2
  end

  describe '#redis_version' do
    it 'returns redis version' do
      @dmr.nodes.first.expects(:redis_version)
      @dmr.redis_version
    end
  end

  describe '#supports_redis_version?' do
    it 'returns redis version' do
      @dmr.nodes.first.expects(:supports_redis_version?).with('2.8.0')
      @dmr.supports_redis_version?('2.8.0')
    end
  end

  describe "namespace" do
    it "uses namespaced key" do
      @dmr = Redis::DistributedStore.new [
        { :host => "localhost", :port => "6380", :db => 0 },
        { :host => "localhost", :port => "6381", :db => 0 }
      ], :namespace => "theplaylist"

      @dmr.expects(:node_for).with("theplaylist:rabbit").returns(@dmr.nodes.first)
      @dmr.get "rabbit"
    end
  end
end unless ENV['CI']
