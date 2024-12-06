shared_examples_for "a sortable" do
  it 'returns empty array on nil' do
    expect(@client.sort(nil)).to eq([])
  end

  context 'ordering' do
    it 'orders ascending by default' do
      expect(@client.sort(@key)).to eq(['1', '2'])
    end

    it 'orders by ascending when specified' do
      expect(@client.sort(@key, :order => "ASC")).to eq(['1', '2'])
    end

    it 'orders by descending when specified' do
      expect(@client.sort(@key, :order => "DESC")).to eq(['2', '1'])
    end

    it "orders by ascending when alpha is specified" do
      expect(@client.sort(@key, :order => "ALPHA")).to eq(["1", "2"])
    end
  end

  context 'projections' do
    it 'projects element when :get is "#"' do
      expect(@client.sort(@key, :get => '#')).to eq(['1', '2'])
    end

    it 'projects through a key pattern' do
      expect(@client.sort(@key, :get => 'fake-redis-test:values_*')).to eq(['a', 'b'])
    end

    it 'projects through a key pattern and reflects element' do
      expect(@client.sort(@key, :get => ['#', 'fake-redis-test:values_*'])).to eq([['1', 'a'], ['2', 'b']])
    end

    it 'projects through a hash key pattern' do
      expect(@client.sort(@key, :get => 'fake-redis-test:hash_*->key')).to eq(['x', 'y'])
    end
  end

  context 'weights' do
    it 'weights by projecting through a key pattern' do
      expect(@client.sort(@key, :by => "fake-redis-test:weight_*")).to eq(['2', '1'])
    end

    it 'weights by projecting through a key pattern and a specific order' do
      expect(@client.sort(@key, :order => "DESC", :by => "fake-redis-test:weight_*")).to eq(['1', '2'])
    end
  end

  context 'limit' do
    it 'only returns requested window in the enumerable' do
      expect(@client.sort(@key, :limit => [0, 1])).to eq(['1'])
    end

    it 'returns an empty array if the offset if more than the length of the list' do
      expect(@client.sort(@key, :limit => [3, 1])).to eq([])
    end
  end

  context 'store' do
    it 'stores into another key' do
      expect(@client.sort(@key, :store => "fake-redis-test:some_bucket")).to eq(2)
      expect(@client.lrange("fake-redis-test:some_bucket", 0, -1)).to eq(['1', '2'])
    end

    it "stores into another key with other options specified" do
      expect(@client.sort(@key, :store => "fake-redis-test:some_bucket", :by => "fake-redis-test:weight_*")).to eq(2)
      expect(@client.lrange("fake-redis-test:some_bucket", 0, -1)).to eq(['2', '1'])
    end
  end
end
