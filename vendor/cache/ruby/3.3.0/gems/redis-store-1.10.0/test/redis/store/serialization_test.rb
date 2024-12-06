require 'test_helper'

describe "Redis::Serialization" do
  def setup
    @store = Redis::Store.new serializer: Marshal
    @rabbit = OpenStruct.new :name => "bunny"
    @white_rabbit = OpenStruct.new :color => "white"
    @store.set "rabbit", @rabbit
    @store.del "rabbit2"
  end

  def teardown
    @store.flushdb
    @store.quit
  end

  it "unmarshals on get" do
    _(@store.get("rabbit")).must_equal(@rabbit)
  end

  it "marshals on set" do
    @store.set "rabbit", @white_rabbit
    _(@store.get("rabbit")).must_equal(@white_rabbit)
  end

  it "marshals on multi set" do
    @store.mset("rabbit", @white_rabbit, "rabbit2", @rabbit)
    _(@store.get("rabbit")).must_equal(@white_rabbit)
    _(@store.get("rabbit2")).must_equal(@rabbit)
  end

  if RUBY_VERSION.match(/1\.9/)
    it "doesn't unmarshal on get if raw option is true" do
      _(@store.get("rabbit", :raw => true)).must_equal("\x04\bU:\x0FOpenStruct{\x06:\tnameI\"\nbunny\x06:\x06EF")
    end
  else
    it "doesn't unmarshal on get if raw option is true" do
      _(@store.get("rabbit", :raw => true)).must_include("\x04\bU:\x0FOpenStruct{\x06:\tname")
    end
  end

  it "doesn't marshal set if raw option is true" do
    @store.set "rabbit", @white_rabbit, :raw => true
    _(@store.get("rabbit", :raw => true)).must_equal(%(#<OpenStruct color="white">))
  end

  it "doesn't marshal multi set if raw option is true" do
    @store.mset("rabbit", @white_rabbit, "rabbit2", @rabbit, :raw => true)
    _(@store.get("rabbit", :raw => true)).must_equal(%(#<OpenStruct color="white">))
    _(@store.get("rabbit2", :raw => true)).must_equal(%(#<OpenStruct name="bunny">))
  end

  it "doesn't unmarshal if get returns an empty string" do
    @store.set "empty_string", ""
    _(@store.get("empty_string")).must_equal("")
    # TODO use a meaningful Exception
    # lambda { @store.get("empty_string").must_equal("") }.wont_raise Exception
  end

  it "doesn't set an object if already exist" do
    @store.setnx "rabbit", @white_rabbit
    _(@store.get("rabbit")).must_equal(@rabbit)
  end

  it "marshals on set unless exists" do
    @store.setnx "rabbit2", @white_rabbit
    _(@store.get("rabbit2")).must_equal(@white_rabbit)
  end

  it "doesn't marshal on set unless exists if raw option is true" do
    @store.setnx "rabbit2", @white_rabbit, :raw => true
    _(@store.get("rabbit2", :raw => true)).must_equal(%(#<OpenStruct color="white">))
  end

  it "marshals on set expire" do
    @store.setex "rabbit2", 1, @white_rabbit
    _(@store.get("rabbit2")).must_equal(@white_rabbit)
    sleep 2
    _(@store.get("rabbit2")).must_be_nil
  end

  unless ENV['CI']
    it "marshals setex (over a distributed store)" do
      @store = Redis::DistributedStore.new [
        { :host => "localhost", :port => "6380", :db => 0 },
        { :host => "localhost", :port => "6381", :db => 0 }
      ]
      @store.setex "rabbit", 50, @white_rabbit
      _(@store.get("rabbit")).must_equal(@white_rabbit)
    end

    it "doesn't marshal setex if raw option is true (over a distributed store)" do
      @store = Redis::DistributedStore.new [
        { :host => "localhost", :port => "6380", :db => 0 },
        { :host => "localhost", :port => "6381", :db => 0 }
      ]
      @store.setex "rabbit", 50, @white_rabbit, :raw => true
      _(@store.get("rabbit", :raw => true)).must_equal(%(#<OpenStruct color="white">))
    end
  end

  it "unmarshals on multi get" do
    @store.set "rabbit2", @white_rabbit
    @store.mget "rabbit", "rabbit2" do |rabbits|
      rabbit, rabbit2 = rabbits
      _(rabbits.length).must_equal(2)
      _(rabbit).must_equal(@rabbit)
      _(rabbit2).must_equal(@white_rabbit)
    end
  end

  it "unmarshals on mapped_mget" do
    @store.set "rabbit2", @white_rabbit
    result = @store.mapped_mget("rabbit", "rabbit2")
    _(result.keys).must_equal %w[ rabbit rabbit2 ]
    _(result["rabbit"]).must_equal @rabbit
    _(result["rabbit2"]).must_equal @white_rabbit
  end

  if RUBY_VERSION.match(/1\.9/)
    it "doesn't unmarshal on multi get if raw option is true" do
      @store.set "rabbit2", @white_rabbit
      @store.mget "rabbit", "rabbit2", :raw => true do |rabbit, rabbit2|
        _(rabbit).must_equal("\x04\bU:\x0FOpenStruct{\x06:\tnameI\"\nbunny\x06:\x06EF")
        _(rabbit2).must_equal("\x04\bU:\x0FOpenStruct{\x06:\ncolorI\"\nwhite\x06:\x06EF")
      end
    end
  else
    it "doesn't unmarshal on multi get if raw option is true" do
      @store.set "rabbit2", @white_rabbit
      @store.mget "rabbit", "rabbit2", :raw => true do |rabbit, rabbit2|
        _(rabbit).must_include("\x04\bU:\x0FOpenStruct{\x06:\tname")
        _(rabbit2).must_include("\x04\bU:\x0FOpenStruct{\x06:\ncolor")
      end
    end
  end

  describe "binary safety" do
    it "marshals objects" do
      utf8_key = [51339].pack("U*")
      ascii_rabbit = OpenStruct.new(:name => [128].pack("C*"))

      @store.set(utf8_key, ascii_rabbit)
      _(@store.get(utf8_key)).must_equal(ascii_rabbit)
    end

    it "gets and sets raw values" do
      utf8_key = [51339].pack("U*")
      ascii_string = [128].pack("C*")

      @store.set(utf8_key, ascii_string, :raw => true)
      _(@store.get(utf8_key, :raw => true).bytes.to_a).must_equal(ascii_string.bytes.to_a)
    end

    it "marshals objects on setnx" do
      utf8_key = [51339].pack("U*")
      ascii_rabbit = OpenStruct.new(:name => [128].pack("C*"))

      @store.del(utf8_key)
      @store.setnx(utf8_key, ascii_rabbit)
      _(@store.get(utf8_key)).must_equal(ascii_rabbit)
    end

    it "gets and sets raw values on setnx" do
      utf8_key = [51339].pack("U*")
      ascii_string = [128].pack("C*")

      @store.del(utf8_key)
      @store.setnx(utf8_key, ascii_string, :raw => true)
      _(@store.get(utf8_key, :raw => true).bytes.to_a).must_equal(ascii_string.bytes.to_a)
    end
  end if defined?(Encoding)
end
