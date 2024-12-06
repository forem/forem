shared_examples_for "a bitwise operation" do |operator|
  it 'raises an argument error when not passed any source keys' do
    expect { @client.bitop(operator, "destkey") }.to raise_error(Redis::CommandError)
  end

  it "should not create destination key if nothing found" do
    expect(@client.bitop(operator, "dest1", "nothing_here1")).to eq(0)
    expect(@client.exists("dest1")).to eq(false)
  end

  it "should accept operator as a case-insensitive symbol" do
    @client.set("key1", "foobar")
    @client.bitop(operator.to_s.downcase.to_sym, "dest1", "key1")
    @client.bitop(operator.to_s.upcase.to_sym, "dest2", "key1")

    expect(@client.get("dest1")).to eq("foobar")
    expect(@client.get("dest2")).to eq("foobar")
  end

  it "should accept operator as a case-insensitive string" do
    @client.set("key1", "foobar")
    @client.bitop(operator.to_s.downcase, "dest1", "key1")
    @client.bitop(operator.to_s.upcase, "dest2", "key1")

    expect(@client.get("dest1")).to eq("foobar")
    expect(@client.get("dest2")).to eq("foobar")
  end

  it "should copy original string for single key" do
    @client.set("key1", "foobar")
    @client.bitop(operator, "dest1", "key1")

    expect(@client.get("dest1")).to eq("foobar")
  end

  it "should copy original string for single key" do
    @client.set("key1", "foobar")
    @client.bitop(operator, "dest1", "key1")

    expect(@client.get("dest1")).to eq("foobar")
  end

  it "should return length of the string stored in the destination key" do
    @client.set("key1", "foobar")
    @client.set("key2", "baz")

    expect(@client.bitop(operator, "dest1", "key1")).to eq(6)
    expect(@client.bitop(operator, "dest2", "key2")).to eq(3)
  end

  it "should overwrite previous value with new one" do
    @client.set("key1", "foobar")
    @client.set("key2", "baz")
    @client.bitop(operator, "dest1", "key1")
    @client.bitop(operator, "dest1", "key2")

    expect(@client.get("dest1")).to eq("baz")
  end
end
