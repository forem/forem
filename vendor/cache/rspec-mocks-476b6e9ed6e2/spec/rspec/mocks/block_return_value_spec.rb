RSpec.describe "a double declaration with a block handed to:" do
  describe "expect(...).to receive" do
    it "returns the value of executing the block" do
      obj = Object.new
      expect(obj).to receive(:foo) { 'bar' }
      expect(obj.foo).to eq('bar')
    end

    it "works when a multi-return stub has already been set" do
      obj = Object.new
      return_value = Object.new
      allow(obj).to receive(:foo).and_return(return_value, nil)
      expect(obj).to receive(:foo) { return_value }
      expect(obj.foo).to be(return_value)
    end
  end

  describe "allow(...).to receive" do
    it "returns the value of executing the block" do
      obj = Object.new
      allow(obj).to receive(:foo) { 'bar' }
      expect(obj.foo).to eq('bar')
    end

    # The "receives a block" part is important: 1.8.7 has a bug that reports the
    # wrong arity when a block receives a block.
    it 'forwards all given args to the block, even when it receives a block' do
      obj = Object.new
      yielded_args = []
      allow(obj).to receive(:foo) { |*args, &_| yielded_args << args }
      obj.foo(1, 2, 3)

      expect(yielded_args).to eq([[1, 2, 3]])
    end
  end

  describe "with" do
    it "returns the value of executing the block" do
      obj = Object.new
      allow(obj).to receive(:foo).with('baz') { 'bar' }
      expect(obj.foo('baz')).to eq('bar')
    end

    it "returns the value of executing the block with given argument" do
      obj = Object.new
      allow(obj).to receive(:foo).with('baz') { |x| 'bar' + x }
      expect(obj.foo('baz')).to eq('barbaz')
    end
  end

  %w[once twice].each do |method|
    describe method do
      it "returns the value of executing the block" do
        obj = Object.new
        allow(obj).to receive(:foo).send(method) { 'bar' }
        expect(obj.foo).to eq('bar')
      end
    end
  end

  describe 'ordered' do
    it "returns the value of executing the block" do
      obj = Object.new
      expect_warning_with_call_site(__FILE__, __LINE__ + 1)
      allow(obj).to receive(:foo).ordered { 'bar' }
      expect(obj.foo).to eq('bar')
    end
  end

  describe "times" do
    it "returns the value of executing the block" do
      obj = Object.new
      allow(obj).to receive(:foo).at_least(1).time { 'bar' }
      expect(obj.foo('baz')).to eq('bar')
    end
  end
end
