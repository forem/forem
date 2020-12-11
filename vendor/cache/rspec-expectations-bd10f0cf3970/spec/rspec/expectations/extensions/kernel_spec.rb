RSpec.describe Object, "#should" do
  before(:example) do
    @target = "target"
    @matcher = double("matcher")
    allow(@matcher).to receive(:matches?).and_return(true)
    allow(@matcher).to receive(:failure_message)
  end

  it "accepts and interacts with a matcher" do
    expect(@matcher).to receive(:matches?).with(@target).and_return(true)
    expect(@target).to @matcher
  end

  it "asks for a failure_message when matches? returns false" do
    expect(@matcher).to receive(:matches?).with(@target).and_return(false)
    expect(@matcher).to receive(:failure_message).and_return("the failure message")
    expect {
      expect(@target).to @matcher
    }.to fail_with("the failure message")
  end

  context "on interpretters that have BasicObject", :if => defined?(BasicObject) do
    let(:proxy_class) do
      Class.new(BasicObject) do
        def initialize(target)
          @target = target
        end

        def proxied?
          true
        end

        def respond_to?(method, *args)
          method.to_sym == :proxied? || @target.respond_to?(symbol, *args)
        end

        def method_missing(name, *args)
          @target.send(name, *args)
        end
      end
    end

    it 'works properly on BasicObject-subclassed proxy objects' do
      expect(proxy_class.new(Object.new)).to be_proxied
    end

    it 'does not break the deprecation check on BasicObject-subclassed proxy objects' do
      begin
        should_enabled = RSpec::Expectations::Syntax.should_enabled?
        RSpec::Expectations::Syntax.enable_should unless should_enabled
        proxy_class.new(BasicObject.new).should be_proxied
      ensure
        RSpec::Expectations::Syntax.disable_should if should_enabled
      end
    end
  end
end

RSpec.describe Object, "#should_not" do
  before(:example) do
    @target = "target"
    @matcher = double("matcher")
  end

  it "accepts and interacts with a matcher" do
    expect(@matcher).to receive(:matches?).with(@target).and_return(false)
    allow(@matcher).to receive(:failure_message_when_negated)

    expect(@target).not_to @matcher
  end

  it "asks for a failure_message_when_negated when matches? returns true" do
    expect(@matcher).to receive(:matches?).with(@target).and_return(true)
    expect(@matcher).to receive(:failure_message_when_negated).and_return("the failure message for should not")
    expect {
      expect(@target).not_to @matcher
    }.to fail_with("the failure message for should not")
  end
end
