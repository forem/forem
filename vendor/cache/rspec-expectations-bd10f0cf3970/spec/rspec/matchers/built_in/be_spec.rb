RSpec.describe "expect(...).to be_predicate" do
  it "passes when actual returns true for :predicate?" do
    actual = double("actual", :happy? => true)
    expect(actual).to be_happy
  end

  it 'allows composable aliases to be defined' do
    RSpec::Matchers.alias_matcher :a_user_who_is_happy, :be_happy
    actual = double("actual", :happy? => true)
    expect(actual).to a_user_who_is_happy
    expect(a_user_who_is_happy.description).to eq("a user who is happy")

    RSpec::Matchers.alias_matcher :a_user_who_is_an_admin, :be_an_admin
    actual = double("actual", :admin? => true)
    expect(actual).to a_user_who_is_an_admin
    expect(a_user_who_is_an_admin.description).to eq("a user who is an admin")

    RSpec::Matchers.alias_matcher :an_animal_that_is_a_canine, :be_a_canine
    actual = double("actual", :canine? => true)
    expect(actual).to an_animal_that_is_a_canine
    expect(an_animal_that_is_a_canine.description).to eq("an animal that is a canine")
  end

  it 'composes gracefully' do
    RSpec::Matchers.alias_matcher :a_happy_object, :be_happy
    expect([
      double,
      double(:happy? => false),
      double(:happy? => true),
    ]).to include a_happy_object
  end

  it "passes when actual returns true for :predicates? (present tense)" do
    actual = double("actual", :exists? => true, :exist? => true)
    expect(actual).to be_exist
  end

  context "when actual returns false for :predicate?" do
    it "fails when actual returns false for :predicate?" do
      actual = double("actual", :happy? => false)
      expect {
        expect(actual).to be_happy
      }.to fail_with("expected `#{actual.inspect}.happy?` to return true, got false")
    end

    it "only calls :predicate? once" do
      actual = double "actual", :happy? => false

      expect(actual).to receive(:happy?).once
      expect { expect(actual).to be_happy }.to fail
    end
  end

  it "fails when actual returns nil for :predicate?" do
    actual = double("actual", :happy? => nil)
    expect {
      expect(actual).to be_happy
    }.to fail_with("expected `#{actual.inspect}.happy?` to return true, got nil")
  end

  context "when strict_predicate_matchers is set to true" do
    it "fails when actual returns 42 for :predicate?" do
      actual = double("actual", :happy? => 42)
      expect {
        expect(actual).to be_happy
      }.to fail_with("expected `#{actual.inspect}.happy?` to return true, got 42")
    end
  end

  context "when strict_predicate_matchers is set to false" do
    around do |example|
      RSpec::Expectations.configuration.strict_predicate_matchers = false
      example.run
      RSpec::Expectations.configuration.strict_predicate_matchers = true
    end

    it "passes when actual returns truthy value for :predicate?" do
      actual = double("actual", :happy? => 42)
      expect(actual).to be_happy
    end

    it "states actual predicate used when it fails" do
      actual = double("actual", :happy? => false)
      expect {
        expect(actual).to be_happy
      }.to fail_with("expected `#{actual.inspect}.happy?` to be truthy, got false")
    end
  end

  it "fails when actual does not respond to :predicate?" do
    expect {
      expect(Object.new).to be_happy
    }.to fail_including("to respond to `happy?`")
  end

  it "indicates when a predicate was attempted to be matched against an unexpected `nil`" do
    expect {
      expect(nil).to be_happy
    }.to fail_including("expected nil to respond to `happy?`")
  end

  it 'handles arguments to the predicate' do
    object = Object.new
    def object.predicate?(return_val); return_val; end
    expect(object).to be_predicate(true)
    expect(object).to_not be_predicate(false)

    expect { expect(object).to be_predicate }.to raise_error(ArgumentError)
    expect { expect(object).to be_predicate(false) }.to fail
    expect { expect(object).not_to be_predicate(true) }.to fail
  end

  it 'handles arguments to the predicate implementing to_hash' do
    object = Object.new
    def object.predicate?(value); value.to_return; end

    hash_a_like =
      Class.new do
        def to_hash
          {:to_return => true}
        end

        def to_return
          true
        end
      end

    expect(object).to be_predicate(hash_a_like.new)
  end

  it 'handles keyword arguments to the predicate', :if => RSpec::Support::RubyFeatures.required_kw_args_supported? do
    object = Object.new
    binding.eval(<<-CODE, __FILE__, __LINE__)
    def object.predicate?(returns:); returns; end

    expect(object).to be_predicate(returns: true)
    expect(object).to_not be_predicate(returns: false)

    expect { expect(object).to be_predicate(returns: false) }.to fail
    expect { expect(object).to_not be_predicate(returns: true) }.to fail
    CODE

    expect { expect(object).to be_predicate }.to raise_error(ArgumentError)
    expect { expect(object).to be_predicate(true) }.to raise_error(ArgumentError)
  end

  it 'falls back to a present-tense form of the predicate when needed' do
    mouth = Object.new
    def mouth.frowns?(return_val); return_val; end

    expect(mouth).to be_frown(true)
  end

  it 'fails when :predicate? is private' do
    privately_happy = Class.new do
      private
        def happy?
          true
        end
    end
    expect { expect(privately_happy.new).to be_happy }.to fail_with(/private/)
  end

  it 'does not call :private_methods when the object publicly responds to the message' do
    publicly_happy = double('happy')
    expect(publicly_happy).to receive(:happy?) { true }
    expect(publicly_happy).not_to receive(:private_methods)
    expect(publicly_happy).to be_happy
  end

  it "fails on error other than NameError" do
    actual = double("actual")
    expect(actual).to receive(:foo?).and_raise("aaaah")
    expect {
      expect(actual).to be_foo
    }.to raise_error(/aaaah/)
  end

  it 'raises an error when :predicate? exists but raises NameError' do
    actual_class = Class.new do
      def foo?
        raise NameError, "aaaah"
      end
    end
    expect {
      expect(actual_class.new).to be_foo
    }.to raise_error(NameError, /aaaah/)
  end

  it "fails on error other than NameError (with the present tense predicate)" do
    actual = double
    expect(actual).to receive(:foos?).and_raise("aaaah")
    expect {
      expect(actual).to be_foo
    }.to raise_error(/aaaah/)
  end

  it "does not support operator chaining like a basic `be` matcher does" do
    matcher = be_happy
    value = double(:happy? => false)
    expect(matcher == value).to be false
  end

  it "indicates `be true` or `be_truthy` when using `be_true`" do
    actual = double("actual")
    expect {
      expect(actual).to be_true
    }.to fail_with(/or perhaps you meant `be true` or `be_truthy`/)
  end

  it "shows no message if actual responds to `true?` when using `be_true`" do
    actual = double("actual", :true? => true)
    expect {
      expect(actual).to be_true
    }.not_to raise_error
  end

  it "indicates `be false` or `be_falsey` when using `be_false`" do
    actual = double("actual")
    expect {
      expect(actual).to be_false
    }.to fail_with(/or perhaps you meant `be false` or `be_falsey`/)
  end

  it "shows no message if actual responds to `false?` when using `be_false`" do
    actual = double("actual", :false? => true)
    expect {
      expect(actual).to be_false
    }.not_to raise_error
  end
end

RSpec.describe "expect(...).not_to be_predicate" do
  let(:strict_predicate_matchers) { true }

  around do |example|
    default = RSpec::Expectations.configuration.strict_predicate_matchers?
    RSpec::Expectations.configuration.strict_predicate_matchers = strict_predicate_matchers
    example.run
    RSpec::Expectations.configuration.strict_predicate_matchers = default
  end

  it "passes when actual returns false for :sym?" do
    actual = double("actual", :happy? => false)
    expect(actual).not_to be_happy
  end

  context "when strict_predicate_matchers is set to true" do
    it "fails when actual returns nil for :sym?" do
      actual = double("actual", :happy? => nil)
      expect {
        expect(actual).not_to be_happy
      }.to fail_with("expected `#{actual.inspect}.happy?` to return false, got nil")
    end
  end

  context "when strict_predicate_matchers is set to false" do
    around do |example|
      RSpec::Expectations.configuration.strict_predicate_matchers = false
      example.run
      RSpec::Expectations.configuration.strict_predicate_matchers = true
    end

    it "passes when actual returns nil for :sym?" do
      actual = double("actual", :happy? => nil)
      expect(actual).not_to be_happy
    end

    it "shows actual comparision made when it fails" do
      actual = double("actual", :happy? => 42)
      expect {
        expect(actual).not_to be_happy
      }.to fail_with("expected `#{actual.inspect}.happy?` to be falsey, got 42")
    end
  end

  it "fails when actual returns true for :sym?" do
    actual = double("actual", :happy? => true)
    expect {
      expect(actual).not_to be_happy
    }.to fail_with("expected `#{actual.inspect}.happy?` to return false, got true")
  end

  it "fails when actual does not respond to :sym?" do
    expect {
      expect(Object.new).not_to be_happy
    }.to fail_including("to respond to `happy?`")
  end
end

RSpec.describe "expect(...).to be_predicate(*args)" do
  it "passes when actual returns true for :predicate?(*args)" do
    actual = double("actual")
    expect(actual).to receive(:older_than?).with(3).and_return(true)
    expect(actual).to be_older_than(3)
  end

  it "fails when actual returns false for :predicate?(*args)" do
    actual = double("actual")
    expect(actual).to receive(:older_than?).with(3).and_return(false)
    expect {
      expect(actual).to be_older_than(3)
    }.to fail_with("expected `#{actual.inspect}.older_than?(3)` to return true, got false")
  end

  it "fails when actual does not respond to :predicate?" do
    expect {
      expect(Object.new).to be_older_than(3)
    }.to fail_including("to respond to `older_than?`")
  end
end

RSpec.describe "expect(...).not_to be_predicate(*args)" do
  it "passes when actual returns false for :predicate?(*args)" do
    actual = double("actual")
    expect(actual).to receive(:older_than?).with(3).and_return(false)
    expect(actual).not_to be_older_than(3)
  end

  it "fails when actual returns true for :predicate?(*args)" do
    actual = double("actual")
    expect(actual).to receive(:older_than?).with(3).and_return(true)
    expect {
      expect(actual).not_to be_older_than(3)
    }.to fail_with("expected `#{actual.inspect}.older_than?(3)` to return false, got true")
  end

  it "fails when actual does not respond to :predicate?" do
    expect {
      expect(Object.new).not_to be_older_than(3)
    }.to fail_including("to respond to `older_than?`")
  end
end

RSpec.describe "expect(...).to be_predicate(&block)" do
  it "passes when actual returns true for :predicate?(&block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:happy?).and_yield
    expect(delegate).to receive(:check_happy).and_return(true)
    expect(actual).to be_happy { delegate.check_happy }
  end

  it "fails when actual returns false for :predicate?(&block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:happy?).and_yield
    expect(delegate).to receive(:check_happy).and_return(false)
    expect {
      expect(actual).to be_happy { delegate.check_happy }
    }.to fail_with("expected `#{actual.inspect}.happy?` to return true, got false")
  end

  it "fails when actual does not respond to :predicate?" do
    delegate = double("delegate", :check_happy => true)
    expect {
      expect(Object.new).to be_happy { delegate.check_happy }
    }.to fail_including("to respond to `happy?`")
  end

  it 'passes the block on to the present-tense predicate form' do
    mouth = Object.new
    def mouth.frowns?; yield; end

    expect(mouth).to be_frown { true }
    expect(mouth).not_to be_frown { false }
  end

  it 'works with a do..end block for either predicate form' do
    mouth1 = Object.new
    def mouth1.frown?; yield; end
    mouth2 = Object.new
    def mouth2.frowns?; yield; end

    expect(mouth1).to be_frown do
      true
    end

    expect(mouth1).not_to be_frown do
      false
    end

    expect(mouth2).to be_frown do
      true
    end

    expect(mouth2).not_to be_frown do
      false
    end
  end

  it 'prefers a { ... } block to a do/end block because it binds more tightly' do
    mouth1 = Object.new
    def mouth1.frown?; yield; end
    mouth2 = Object.new
    def mouth2.frowns?; yield; end

    expect(mouth1).to be_frown { true } do
      false
    end

    expect(mouth1).not_to be_frown { false } do
      true
    end

    expect(mouth2).to be_frown { true } do
      false
    end

    expect(mouth2).not_to be_frown { false } do
      true
    end
  end
end

RSpec.describe "expect(...).not_to be_predicate(&block)" do
  it "passes when actual returns false for :predicate?(&block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:happy?).and_yield
    expect(delegate).to receive(:check_happy).and_return(false)
    expect(actual).not_to be_happy { delegate.check_happy }
  end

  it "fails when actual returns true for :predicate?(&block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:happy?).and_yield
    expect(delegate).to receive(:check_happy).and_return(true)
    expect {
      expect(actual).not_to be_happy { delegate.check_happy }
    }.to fail_with("expected `#{actual.inspect}.happy?` to return false, got true")
  end

  it "fails when actual does not respond to :predicate?" do
    delegate = double("delegate", :check_happy => true)
    expect {
      expect(Object.new).not_to be_happy { delegate.check_happy }
    }.to fail_including("to respond to `happy?`")
  end
end

RSpec.describe "expect(...).to be_predicate(*args, &block)" do
  it "passes when actual returns true for :predicate?(*args, &block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:older_than?).with(3).and_yield(3)
    expect(delegate).to receive(:check_older_than).with(3).and_return(true)
    expect(actual).to be_older_than(3) { |age| delegate.check_older_than(age) }
  end

  it "fails when actual returns false for :predicate?(*args, &block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:older_than?).with(3).and_yield(3)
    expect(delegate).to receive(:check_older_than).with(3).and_return(false)
    expect {
      expect(actual).to be_older_than(3) { |age| delegate.check_older_than(age) }
    }.to fail_with("expected `#{actual.inspect}.older_than?(3)` to return true, got false")
  end

  it "fails when actual does not respond to :predicate?" do
    delegate = double("delegate", :check_older_than => true)
    expect {
      expect(Object.new).to be_older_than(3) { |age| delegate.check_older_than(age) }
    }.to fail_including("to respond to `older_than?`")
  end
end

RSpec.describe "expect(...).not_to be_predicate(*args, &block)" do
  it "passes when actual returns false for :predicate?(*args, &block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:older_than?).with(3).and_yield(3)
    expect(delegate).to receive(:check_older_than).with(3).and_return(false)
    expect(actual).not_to be_older_than(3) { |age| delegate.check_older_than(age) }
  end

  it "fails when actual returns true for :predicate?(*args, &block)" do
    actual = double("actual")
    delegate = double("delegate")
    expect(actual).to receive(:older_than?).with(3).and_yield(3)
    expect(delegate).to receive(:check_older_than).with(3).and_return(true)
    expect {
      expect(actual).not_to be_older_than(3) { |age| delegate.check_older_than(age) }
    }.to fail_with("expected `#{actual.inspect}.older_than?(3)` to return false, got true")
  end

  it "fails when actual does not respond to :predicate?" do
    delegate = double("delegate", :check_older_than => true)
    expect {
      expect(Object.new).not_to be_older_than(3) { |age| delegate.check_older_than(age) }
    }.to fail_including("to respond to `older_than?`")
  end
end

RSpec.describe "expect(...).to be_truthy" do
  it "passes when actual equal?(true)" do
    expect(true).to be_truthy
  end

  it "passes when actual is 1" do
    expect(1).to be_truthy
  end

  it "fails when actual equal?(false)" do
    expect {
      expect(false).to be_truthy
    }.to fail_with("expected: truthy value\n     got: false")
  end
end

RSpec.describe "expect(...).to be_falsey" do
  it "passes when actual equal?(false)" do
    expect(false).to be_falsey
  end

  it "passes when actual equal?(nil)" do
    expect(nil).to be_falsey
  end

  it "fails when actual equal?(true)" do
    expect {
      expect(true).to be_falsey
    }.to fail_with("expected: falsey value\n     got: true")
  end
end

RSpec.describe "expect(...).to be_falsy" do
  it "passes when actual equal?(false)" do
    expect(false).to be_falsy
  end

  it "passes when actual equal?(nil)" do
    expect(nil).to be_falsy
  end

  it "fails when actual equal?(true)" do
    expect {
      expect(true).to be_falsy
    }.to fail_with("expected: falsey value\n     got: true")
  end
end

RSpec.describe "expect(...).to be_nil" do
  it "passes when actual is nil" do
    expect(nil).to be_nil
  end

  it "fails when actual is not nil" do
    expect {
      expect(:not_nil).to be_nil
    }.to fail_with(/^expected: nil/)
  end
end

RSpec.describe "expect(...).not_to be_nil" do
  it "passes when actual is not nil" do
    expect(:not_nil).not_to be_nil
  end

  it "fails when actual is nil" do
    expect {
      expect(nil).not_to be_nil
    }.to fail_with(/^expected: not nil/)
  end
end

RSpec.describe "expect(...).to be <" do
  it "passes when < operator returns true" do
    expect(3).to be < 4
    expect('a').to be < 'b'
  end

  it "fails when < operator returns false" do
    expect {
      expect(3).to be < 3
    }.to fail_with("expected: < 3\n     got:   3")

    expect {
      expect('a').to be < 'a'
    }.to fail_with(%(expected: < "a"\n     got:   "a"))
  end

  it "fails when < operator raises ArgumentError" do
    expect {
      expect('a').to be < 1
    }.to fail_with(%(expected: < 1\n     got:   "a"))
  end

  it 'fails when < operator is not defined' do
    expect {
      expect(nil).to be < 1
    }.to fail_with(%(expected: < 1\n     got:   nil))
  end

  it "describes itself" do
    expect(be.<(4).description).to eq "be < 4"
  end

  it 'does not lie and say that it is equal to a number' do
    matcher = (be < 3)
    expect(5 == matcher).to be false
  end
end

RSpec.describe "expect(...).to be <=" do
  it "passes when <= operator returns true" do
    expect(3).to be <= 4
    expect(4).to be <= 4
    expect('a').to be <= 'b'
    expect('a').to be <= 'a'
  end

  it "fails when <= operator returns false" do
    expect {
      expect(3).to be <= 2
    }.to fail_with("expected: <= 2\n     got:    3")

    expect {
      expect('c').to be <= 'a'
    }.to fail_with(%(expected: <= "a"\n     got:    "c"))
  end

  it "fails when <= operator raises ArgumentError" do
    expect {
      expect('a').to be <= 1
    }.to fail_with(%(expected: <= 1\n     got:    "a"))
  end

  it 'fails when <= operator is not defined' do
    expect {
      expect(nil).to be <= 1
    }.to fail_with(%(expected: <= 1\n     got:    nil))
  end
end

RSpec.describe "expect(...).to be >=" do
  it "passes when >= operator returns true" do
    expect(4).to be >= 4
    expect(5).to be >= 4
  end

  it "fails when >= operator returns false" do
    expect {
      expect(3).to be >= 4
    }.to fail_with("expected: >= 4\n     got:    3")

    expect {
      expect('a').to be >= 'c'
    }.to fail_with(%(expected: >= "c"\n     got:    "a"))
  end

  it "fails when >= operator raises ArgumentError" do
    expect {
      expect('a').to be >= 1
    }.to fail_with(%(expected: >= 1\n     got:    "a"))
  end

  it 'fails when >= operator is not defined' do
    expect {
      expect(nil).to be >= 1
    }.to fail_with(%(expected: >= 1\n     got:    nil))
  end
end

RSpec.describe "expect(...).to be >" do
  it "passes when > operator returns true" do
    expect(5).to be > 4
  end

  it "fails when > operator returns false" do
    expect {
      expect(3).to be > 4
    }.to fail_with("expected: > 4\n     got:   3")

    expect {
      expect('a').to be > 'a'
    }.to fail_with(%(expected: > "a"\n     got:   "a"))
  end

  it "fails when > operator raises ArgumentError" do
    expect {
      expect('a').to be > 1
    }.to fail_with(%(expected: > 1\n     got:   "a"))
  end

  it 'fails when > operator is not defined' do
    expect {
      expect(nil).to be > 1
    }.to fail_with(%(expected: > 1\n     got:   nil))
  end
end

RSpec.describe "expect(...).to be ==" do
  it "passes when == operator returns true" do
    expect(5).to be == 5
  end

  it "fails when == operator returns false" do
    expect {
      expect(3).to be == 4
    }.to fail_with("expected: == 4\n     got:    3")

    expect {
      expect('a').to be == 'c'
    }.to fail_with(%(expected: == "c"\n     got:    "a"))
  end

  it "fails when == operator raises ArgumentError" do
    failing_equality_klass = Class.new do
      def inspect
        "<Class>"
      end

      def ==(other)
        raise ArgumentError
      end
    end

    expect {
      expect(failing_equality_klass.new).to be == 1
    }.to fail_with(%(expected: == 1\n     got:    <Class>))
  end

  it 'works when the target overrides `#send`' do
    klass = Struct.new(:message) do
      def send
        :message_sent
      end
    end

    msg_1 = klass.new("hello")
    msg_2 = klass.new("hello")
    expect(msg_1).to be == msg_2
  end
end

RSpec.describe "expect(...).to be =~" do
  it "passes when =~ operator returns true" do
    expect("a string").to be =~ /str/
  end

  it "fails when =~ operator returns false" do
    expect {
      expect("a string").to be =~ /blah/
    }.to fail_with(%(expected: =~ /blah/\n     got:    "a string"))
  end
end

RSpec.describe "should be =~", :uses_should do
  it "passes when =~ operator returns true" do
    "a string".should be =~ /str/
  end

  it "fails when =~ operator returns false" do
    expect {
      "a string".should be =~ /blah/
    }.to fail_with(%(expected: =~ /blah/\n     got:    "a string"))
  end
end

RSpec.describe "expect(...).to be ===" do
  it "passes when === operator returns true" do
    expect(Hash).to be === {}
  end

  it "fails when === operator returns false" do
    expect {
      expect(Hash).to be === "not a hash"
    }.to fail_with(%(expected: === "not a hash"\n     got:     Hash))
  end
end

RSpec.describe "expect(...).not_to with comparison operators" do
  it "coaches user to stop using operators with expect().not_to with numerical comparison operators" do
    expect {
      expect(5).not_to be < 6
    }.to fail_with("`expect(5).not_to be < 6` not only FAILED, it is a bit confusing.")

    expect {
      expect(5).not_to be <= 6
    }.to fail_with("`expect(5).not_to be <= 6` not only FAILED, it is a bit confusing.")

    expect {
      expect(6).not_to be > 5
    }.to fail_with("`expect(6).not_to be > 5` not only FAILED, it is a bit confusing.")

    expect {
      expect(6).not_to be >= 5
    }.to fail_with("`expect(6).not_to be >= 5` not only FAILED, it is a bit confusing.")
  end

  it "coaches users to stop using negation with string comparison operators" do
    expect {
      expect("foo").not_to be > "bar"
    }.to fail_with('`expect("foo").not_to be > "bar"` not only FAILED, it is a bit confusing.')
  end

  it "handles ArgumentError as a failure" do
    [:<, :<=, :>=, :>].each do |operator|
      expect {
        expect('a').to_not be.send(operator, 1)
      }.to fail_with(%(`expect("a").not_to be #{operator} 1` not only FAILED, it is a bit confusing.))
    end
  end

  it "handles NameError as a failure" do
    [:<, :<=, :>=, :>].each do |operator|
      expect {
        expect(
          Class.new do
            def inspect
              '<Class>'
            end

            define_method(operator) { |arg| self.non_existant_attribute == operator }
          end.new
        ).to_not be.send(operator, 1)
      }.to fail_with(%(`expect(<Class>).not_to be #{operator} 1` not only FAILED, it is a bit confusing.))
    end
  end
end

RSpec.describe "expect(...).not_to with equality operators" do
  it "raises normal error with expect().not_to with equality operators" do
    expect {
      expect(6).not_to be == 6
    }.to fail_with("`expect(6).not_to be == 6`")

    expect {
      expect(String).not_to be === "Hello"
    }.to fail_with('`expect(String).not_to be === "Hello"`')
  end

  it "handles ArgumentError as a failure" do
    failing_equality_klass = Class.new do
      def inspect
        "<Class>"
      end

      def ==(other)
        raise ArgumentError
      end
    end

    expect {
      expect(failing_equality_klass.new).not_to be == 1
    }.to fail_with(%(`expect(<Class>).not_to be == 1`))

    expect {
      expect(failing_equality_klass.new).not_to be === 1
    }.to fail_with(%(`expect(<Class>).not_to be === 1`))
  end

  it "handles NameError as a failure" do
    failing_equality_klass = Class.new do
      def inspect
        "<Class>"
      end

      undef ==
    end

    expect {
      expect(failing_equality_klass.new).not_to be == 1
    }.to fail_with(%(`expect(<Class>).not_to be == 1`))

    expect {
      expect(failing_equality_klass.new).not_to be === 1
    }.to fail_with(%(`expect(<Class>).not_to be === 1`))
  end
end

RSpec.describe "expect(...).to be" do
  it "passes if actual is truthy" do
    expect(true).to be
    expect(1).to be
  end

  it "fails if actual is false" do
    expect {
      expect(false).to be
    }.to fail_with("expected false to evaluate to true")
  end

  it "fails if actual is nil" do
    expect {
      expect(nil).to be
    }.to fail_with("expected nil to evaluate to true")
  end

  it "describes itself" do
    expect(be.description).to eq "be"
  end
end

RSpec.describe "expect(...).not_to be" do
  it "passes if actual is falsy" do
    expect(false).not_to be
    expect(nil).not_to be
  end

  it "fails on true" do
    expect {
      expect(true).not_to be
    }.to fail_with("expected true to evaluate to false")
  end
end

RSpec.describe "expect(...).to be(value)" do
  it "delegates to equal" do
    matcher = equal(5)
    expect(self).to receive(:equal).with(5).and_return(matcher)
    expect(5).to be(5)
  end
end

RSpec.describe "expect(...).not_to be(value)" do
  it "delegates to equal" do
    matcher = equal(4)
    expect(self).to receive(:equal).with(4).and_return(matcher)
    expect(5).not_to be(4)
  end
end

RSpec.describe "'expect(...).to be' with operator" do
  it "includes 'be' in the description" do
    expect((be > 6).description).to match(/be > 6/)
    expect((be >= 6).description).to match(/be >= 6/)
    expect((be <= 6).description).to match(/be <= 6/)
    expect((be < 6).description).to match(/be < 6/)
  end
end

RSpec.describe "arbitrary predicate with DelegateClass" do
  it "accesses methods defined in the delegating class (LH[#48])" do
    in_sub_process_if_possible do
      require 'delegate'
      class ArrayDelegate < DelegateClass(Array)
        def initialize(array)
          @internal_array = array
          super(@internal_array)
        end

        def large?
          @internal_array.size >= 5
        end
      end

      delegate = ArrayDelegate.new([1, 2, 3, 4, 5, 6])
      expect(delegate).to be_large
    end
  end
end

RSpec.describe "be_a, be_an" do
  it "passes when class matches" do
    expect("foobar").to be_a(String)
    expect([1, 2, 3]).to be_an(Array)
  end

  it "fails when class does not match" do
    expect("foobar").not_to be_a(Hash)
    expect([1, 2, 3]).not_to be_an(Integer)
  end
end

RSpec.describe "be_an_instance_of" do
  it "passes when direct class matches" do
    expect("string").to be_an_instance_of(String)
  end

  it "fails when class is higher up hierarchy" do
    expect(5).not_to be_an_instance_of(Numeric)
  end
end
