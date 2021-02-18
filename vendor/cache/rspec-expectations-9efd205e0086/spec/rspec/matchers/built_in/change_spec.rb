class SomethingExpected
  attr_accessor :some_value
end

value_pattern = /(?:result|`.+?`)/

RSpec.describe "expect { ... }.to change ..." do
  context "with a numeric value" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = 5
    end

    it "passes when actual is modified by the block" do
      expect { @instance.some_value = 6.0 }.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected `SomethingExpected#some_value` to have changed, but is still 5")
    end

    it "provides a #description" do
      expect(change(@instance, :some_value).description).to eq "change `SomethingExpected#some_value`"
    end
  end

  it "can specify the change of a variable's class" do
    val = nil

    expect {
      val = "string"
    }.to change { val.class }.from(NilClass).to(String)

    expect {
      expect {
        val = :symbol
      }.to change { val.class }.from(String).to(NilClass)
    }.to fail_with(/but is now Symbol/)
  end

  context "with boolean values" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = true
    end

    it "passes when actual is modified by the block" do
      expect { @instance.some_value = false }.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected `SomethingExpected#some_value` to have changed, but is still true")
    end
  end

  context "with set values" do
    it "passes when it should" do
      in_sub_process_if_possible do
        require 'set'

        set = Set.new([1])
        expect {
          set << 2
        }.to change { set }.from([1].to_set).to([2, 1].to_set)
      end
    end

    it "fails when it should" do
      in_sub_process_if_possible do
        require 'set'

        expect {
          set = Set.new([1])
          expect {
            set << 2
          }.to change { set }.from([1].to_set).to([2, 1, 3].to_set)
        }.to fail_with(/expected #{value_pattern} to have changed to #{Regexp.escape([2, 1, 3].to_set.inspect)}, but is now #{Regexp.escape([1, 2].to_set.inspect)}/)
      end
    end
  end

  context "with an IO stream" do
    it "fails when the stream does not change" do
      expect {
        k = STDOUT
        expect {}.to change { k }
      }.to fail_with(/expected #{value_pattern} to have changed/)
    end
  end

  it 'correctly detects a change that both mutates and replaces an object' do
    obj = Struct.new(:x).new([])

    expect {
      obj.x << 1 # mutate it
      obj.x = [1] # replace it
    }.to change { obj.x }
  end

  it 'does not detect changes in an object that updates its hash upon comparison' do
    obj = Class.new do
      def ==(another)
        @hash = rand # (^ '=')^ #
        object_id == another.object_id
      end
      def hash
        @hash ||= super
      end
    end.new

    expect {}.not_to change { obj }
  end

  context "with nil value" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = nil
    end

    it "passes when actual is modified by the block" do
      expect { @instance.some_value = false }.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected `SomethingExpected#some_value` to have changed, but is still nil")
    end
  end

  context "with a deeply nested object graph" do
    it "passes when a leaf is changed" do
      data = [{ :a => [1, 2] }]
      expect { data[0][:a] << 3 }.to change { data }
    end

    it 'fails when no part of it is changed' do
      data = [{ :a => [1, 2] }]
      failure_msg = /expected #{value_pattern} to have changed, but is still #{regexp_inspect data}/

      expect {
        expect { data.to_s }.to change { data }
      }.to fail_with(failure_msg)
    end

    it "passes when correctly specifying the exact mutation of a leaf" do
      data = [{ :a => [1, 2] }]

      expect { data[0][:a] << 3 }.to change { data }.
          from([{ :a => [1, 2] }]).
          to([{ :a => [1, 2, 3] }])
    end

    it "fails when wrongly specifying the `from` value" do
      data = [{ :a => [1, 2] }]
      expected_initial = [{ :a => [1] }]
      failure_msg = /expected #{value_pattern} to have initially been #{regexp_inspect expected_initial}, but was #{regexp_inspect data}/

      expect {
        expect { data[0][:a] << 3 }.to change { data }.
            from(expected_initial).
            to([{ :a => [1, 2, 3] }])
      }.to fail_with(failure_msg)
    end

    it "fails when wrongly specifying the `to` value" do
      data = [{ :a => [1, 2] }]
      expected_final = [{ :a => [1] }]
      failure_msg = /expected #{value_pattern} to have changed to #{regexp_inspect expected_final}, but is now #{regexp_inspect [{ :a => [1, 2, 3] }]}/

      expect {
        expect { data[0][:a] << 3 }.to change { data }.
            from([{ :a => [1, 2] }]).
            to(expected_final)
      }.to fail_with(failure_msg)
    end

    def regexp_inspect(object)
      Regexp.escape(object.inspect)
    end
  end

  context "with an array" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = []
    end

    it "passes when actual is modified by the block" do
      expect { @instance.some_value << 1 }.to change(@instance, :some_value)
    end

    it "fails when a predicate on the actual fails" do
      expect do
        expect { @instance.some_value << 1 }.to change { @instance.some_value }.to be_empty
      end.to fail_with(/#{value_pattern} to have changed to/)
    end

    it "passes when a predicate on the actual passes" do
      @instance.some_value = [1]
      expect { @instance.some_value.pop }.to change { @instance.some_value }.to be_empty
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with("expected `SomethingExpected#some_value` to have changed, but is still []")
    end
  end

  context "with a hash" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = { :a => 'a' }
    end

    it "passes when actual is modified by the block" do
      expect { @instance.some_value[:a] = 'A' }.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail
    end
  end

  context "with a string" do
    it "passes when actual is modified by the block" do
      string = "ab".dup
      expect { string << "c" }.to change { string }
    end

    it 'fails when actual is not modified by the block' do
      string = "ab"
      expect {
        expect {}.to change { string }
      }.to fail_with(/to have changed/)
    end
  end

  context "with an arbitrary enumerable" do
    before(:example) do
      @instance = SomethingExpected.new
      # rubocop:disable Layout/EmptyLinesAroundArguments This is a RuboCop bug, and it's fixed in 0.65.0
      @instance.some_value = Class.new do
        include Enumerable

        attr_reader :elements

        def initialize(*elements)
          @elements = elements.dup
        end

        def <<(element)
          elements << element
        end

        def dup
          self.class.new(*elements)
        end

        def ==(other)
          elements == other.elements
        end

        def hash
          elements.hash
        end
      end.new
      # rubocop:enable Layout/EmptyLinesAroundArguments
    end

    it "passes when actual is modified by the block" do
      expect { @instance.some_value << 1 }.to change(@instance, :some_value)
    end

    it "fails when actual is not modified by the block" do
      expect do
        expect {}.to change(@instance, :some_value)
      end.to fail_with(/^expected `SomethingExpected#some_value` to have changed, but is still/)
    end
  end
end

RSpec.describe "expect { ... }.to change(actual, message)" do
  it 'provides a #description with `SomeClass#some_message` notation' do
    expect(change('instance', :some_value).description).to eq 'change `String#some_value`'
  end

  context "when the receiver is an instance of anonymous class" do
    let(:klass) do
      Class.new(SomethingExpected)
    end

    it "can handle it" do
      expect(change(klass.new, :some_value).description).to match(/change `#<Class:.*?>#some_value`/)
    end
  end

  context 'when the receiver is an object that does not respond to #class such as BasicObject' do
    let(:basic_object) do
      basic_object_class.new
    end

    let(:basic_object_class) do
      defined?(BasicObject) ? BasicObject : fake_basic_object_class
    end

    let(:fake_basic_object_class) do
      Class.new do
        def self.to_s
          'BasicObject'
        end

        undef class, inspect, respond_to?
      end
    end

    it 'can properly extract the class name' do
      expect(change(basic_object, :__id__).description).to eq 'change `BasicObject#__id__`'
    end
  end

  context "when the receiver is a Module" do
    it "provides a #description with `SomeModule.some_message` notation" do
      expect(change(SomethingExpected, :some_value).description).to match(/change `SomethingExpected.some_value`/)
    end
  end

  context "with a missing message" do
    it "fails with an ArgumentError" do
      expect do
        expect {}.to change(:receiver)
      end.to raise_error(ArgumentError, /^`change` requires either an object and message/)
    end
  end
end

RSpec.describe "expect { ... }.not_to change(actual, message)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when actual is not modified by the block" do
    expect {}.not_to change(@instance, :some_value)
  end

  it "fails when actual is not modified by the block" do
    expect do
      expect { @instance.some_value = 6 }.not_to change(@instance, :some_value)
    end.to fail_with("expected `SomethingExpected#some_value` not to have changed, but did change from 5 to 6")
  end
end

RSpec.describe "expect { ... }.to change { block }" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when actual is modified by the block" do
    expect { @instance.some_value = 6 }.to change { @instance.some_value }
  end

  it "fails when actual is not modified by the block" do
    expect do
      expect {}.to change { @instance.some_value }
    end.to fail_with(/expected #{value_pattern} to have changed, but is still 5/)
  end

  it "warns if passed a block using do/end instead of {}" do
    expect do
      expect {}.to change do; end
    end.to raise_error(SyntaxError, /Block not received by the `change` matcher/)
  end

  context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
    context 'when the block body fits into a single line' do
      it "provides a #description with the block snippet" do
        expect(change { @instance.some_value }.description).to eq "change `@instance.some_value`"
      end
    end

    context 'when the block body spans multiple lines' do
      before do
        def @instance.reload
        end
      end

      let(:matcher) do
        change {
          @instance.reload
          @instance.some_value
        }
      end

      it "provides a #description with the block snippet" do
        expect(matcher.description).to eq "change result"
      end
    end

    context 'when used with an alias name' do
      alias_matcher :modify, :change

      it 'can extract the block snippet' do
        expect(modify { @instance.some_value }.description).to eq "modify `@instance.some_value`"
      end
    end
  end

  context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description without the block snippet" do
      expect(change { @instance.some_value }.description).to eq "change result"
    end
  end
end

RSpec.describe "expect { ... }.not_to change { block }" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when actual is modified by the block" do
    expect {}.not_to change { @instance.some_value }
  end

  it "fails when actual is not modified by the block" do
    expect do
      expect { @instance.some_value = 6 }.not_to change { @instance.some_value }
    end.to fail_with(/expected #{value_pattern} not to have changed, but did change from 5 to 6/)
  end

  it "warns if passed a block using do/end instead of {}" do
    expect do
      expect {}.not_to change do; end
    end.to raise_error(SyntaxError, /Block not received by the `change` matcher/)
  end

  context "with an IO stream" do
    it "passes when the stream does not change" do
      k = STDOUT
      expect {}.not_to change { k }
    end
  end

  context "with a deeply nested object graph" do
    it "passes when the object is changed" do
      data = [{ :a => [1, 2] }]
      expect { data.to_s }.not_to change { data }
    end

    it 'fails when part of it is changed' do
      data = [{ :a => [1, 2] }]
      failure_msg = /expected #{value_pattern} not to have changed, but did change from #{regexp_inspect data} to #{regexp_inspect [{ :a=>[1, 2, 3] }]}/

      expect {
        expect { data[0][:a] << 3 }.not_to change { data }
      }.to fail_with(failure_msg)
    end

    it "passes when correctly specifying the exact mutation of a leaf" do
      data = [{ :a => [1, 2] }]

      expect { data[0][:a] << 3 }.to change { data }.
          from([{ :a => [1, 2] }]).
          to([{ :a => [1, 2, 3] }])
    end

    def regexp_inspect(object)
      Regexp.escape(object.inspect)
    end
  end
end

RSpec.describe "expect { ... }.not_to change { }.from" do
  context 'when the value starts at the from value' do
    it 'passes when the value does not change' do
      k = 5
      expect {}.not_to change { k }.from(5)
    end

    it 'fails when the value does change' do
      expect {
        k = 5
        expect { k += 1 }.not_to change { k }.from(5)
      }.to fail_with(/but did change from 5 to 6/)
    end
  end

  context 'when the value starts at a different value' do
    it 'fails when the value does not change' do
      expect {
        k = 6
        expect {}.not_to change { k }.from(5)
      }.to fail_with(/expected #{value_pattern} to have initially been 5/)
    end

    it 'fails when the value does change' do
      expect {
        k = 6
        expect { k += 1 }.not_to change { k }.from(5)
      }.to fail_with(/expected #{value_pattern} to have initially been 5/)
    end
  end
end

RSpec.describe "expect { ... }.not_to change { }.to" do
  it 'is not supported' do
    expect {
      expect {}.not_to change {}.to(3)
    }.to raise_error(NotImplementedError)
  end

  it 'is not supported when it comes after `from`' do
    expect {
      expect {}.not_to change {}.from(nil).to(3)
    }.to raise_error(NotImplementedError)
  end
end

RSpec.describe "expect { ... }.not_to change { }.by" do
  it 'is not supported' do
    expect {
      expect {}.not_to change {}.by(3)
    }.to raise_error(NotImplementedError)
  end
end

RSpec.describe "expect { ... }.not_to change { }.by_at_least" do
  it 'is not supported' do
    expect {
      expect {}.not_to change {}.by_at_least(3)
    }.to raise_error(NotImplementedError)
  end
end

RSpec.describe "expect { ... }.not_to change { }.by_at_most" do
  it 'is not supported' do
    expect {
      expect {}.not_to change {}.by_at_most(3)
    }.to raise_error(NotImplementedError)
  end
end

RSpec.describe "expect { ... }.to change(actual, message).by(expected)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by expected amount" do
    expect { @instance.some_value += 1 }.to change(@instance, :some_value).by(1)
  end

  it "passes when attribute is not changed and expected amount is 0" do
    expect { @instance.some_value += 0 }.to change(@instance, :some_value).by(0)
  end

  it "fails when the attribute is changed by unexpected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change(@instance, :some_value).by(1)
    end.to fail_with("expected `SomethingExpected#some_value` to have changed by 1, but was changed by 2")
  end

  it "fails when the attribute is changed by unexpected amount in the opposite direction" do
    expect do
      expect { @instance.some_value -= 1 }.to change(@instance, :some_value).by(1)
    end.to fail_with("expected `SomethingExpected#some_value` to have changed by 1, but was changed by -1")
  end

  it "provides a #description" do
    expect(change(@instance, :some_value).by(3).description).to eq "change `SomethingExpected#some_value` by 3"
  end
end

RSpec.describe "expect { ... }.to change { block }.by(expected)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by expected amount" do
    expect { @instance.some_value += 1 }.to change { @instance.some_value }.by(1)
  end

  it "fails when the attribute is changed by unexpected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change { @instance.some_value }.by(1)
    end.to fail_with(/expected #{value_pattern} to have changed by 1, but was changed by 2/)
  end

  it "fails when the attribute is changed by unexpected amount in the opposite direction" do
    expect do
      expect { @instance.some_value -= 1 }.to change { @instance.some_value }.by(1)
    end.to fail_with(/expected #{value_pattern} to have changed by 1, but was changed by -1/)
  end

  context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description with the block snippet" do
      expect(change { @instance.some_value }.by(3).description).to eq "change `@instance.some_value` by 3"
    end
  end

  context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description without the block snippet" do
      expect(change { @instance.some_value }.by(3).description).to eq "change result by 3"
    end
  end
end

RSpec.describe "expect { ... }.to change(actual, message).by_at_least(expected)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by greater than the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_least(1)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_least(2)
  end

  it "fails when the attribute is changed by less than the expected amount" do
    expect do
      expect { @instance.some_value += 1 }.to change(@instance, :some_value).by_at_least(2)
    end.to fail_with("expected `SomethingExpected#some_value` to have changed by at least 2, but was changed by 1")
  end

  it "provides a #description" do
    expect(change(@instance, :some_value).by_at_least(3).description).to eq "change `SomethingExpected#some_value` by at least 3"
  end
end

RSpec.describe "expect { ... }.to change { block }.by_at_least(expected)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by greater than expected amount" do
    expect { @instance.some_value += 2 }.to change { @instance.some_value }.by_at_least(1)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change { @instance.some_value }.by_at_least(2)
  end

  it "fails when the attribute is changed by less than the unexpected amount" do
    expect do
      expect { @instance.some_value += 1 }.to change { @instance.some_value }.by_at_least(2)
    end.to fail_with(/expected #{value_pattern} to have changed by at least 2, but was changed by 1/)
  end

  context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description with the block snippet" do
      expect(change { @instance.some_value }.by_at_least(3).description).to eq "change `@instance.some_value` by at least 3"
    end
  end

  context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description without the block snippet" do
      expect(change { @instance.some_value }.by_at_least(3).description).to eq "change result by at least 3"
    end
  end
end

RSpec.describe "expect { ... }.to change(actual, message).by_at_most(expected)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by less than the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_most(3)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_most(2)
  end

  it "fails when the attribute is changed by greater than the expected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change(@instance, :some_value).by_at_most(1)
    end.to fail_with("expected `SomethingExpected#some_value` to have changed by at most 1, but was changed by 2")
  end

  it "provides a #description" do
    expect(change(@instance, :some_value).by_at_most(3).description).to eq "change `SomethingExpected#some_value` by at most 3"
  end
end

RSpec.describe "expect { ... }.to change { block }.by_at_most(expected)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 5
  end

  it "passes when attribute is changed by less than expected amount" do
    expect { @instance.some_value += 2 }.to change { @instance.some_value }.by_at_most(3)
  end

  it "passes when attribute is changed by the expected amount" do
    expect { @instance.some_value += 2 }.to change { @instance.some_value }.by_at_most(2)
  end

  it "fails when the attribute is changed by greater than the unexpected amount" do
    expect do
      expect { @instance.some_value += 2 }.to change { @instance.some_value }.by_at_most(1)
    end.to fail_with(/expected #{value_pattern} to have changed by at most 1, but was changed by 2/)
  end

  context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description with the block snippet" do
      expect(change { @instance.some_value }.by_at_most(3).description).to eq "change `@instance.some_value` by at most 3"
    end
  end

  context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description without the block snippet" do
      expect(change { @instance.some_value }.by_at_most(3).description).to eq "change result by at most 3"
    end
  end
end

RSpec.describe "expect { ... }.to change(actual, message).from(old)" do
  context "with boolean values" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = true
    end

    it "passes when attribute is == to expected value before executing block" do
      expect { @instance.some_value = false }.to change(@instance, :some_value).from(true)
    end

    it "fails when attribute is not == to expected value before executing block" do
      expect do
        expect { @instance.some_value = 'foo' }.to change(@instance, :some_value).from(false)
      end.to fail_with("expected `SomethingExpected#some_value` to have initially been false, but was true")
    end
  end

  context "with non-boolean values" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = 'string'
    end

    it "passes when attribute matches expected value before executing block" do
      expect { @instance.some_value = "astring" }.to change(@instance, :some_value).from("string")
    end

    it "fails when attribute does not match expected value before executing block" do
      expect do
        expect { @instance.some_value = "knot" }.to change(@instance, :some_value).from("cat")
      end.to fail_with("expected `SomethingExpected#some_value` to have initially been \"cat\", but was \"string\"")
    end

    it "provides a #description" do
      expect(change(@instance, :some_value).from(3).description).to eq "change `SomethingExpected#some_value` from 3"
    end
  end
end

RSpec.describe "expect { ... }.to change { block }.from(old)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  it "passes when attribute matches expected value before executing block" do
    expect { @instance.some_value = "astring" }.to change { @instance.some_value }.from("string")
  end

  it "fails when attribute does not match expected value before executing block" do
    expect do
      expect { @instance.some_value = "knot" }.to change { @instance.some_value }.from("cat")
    end.to fail_with(/expected #{value_pattern} to have initially been "cat", but was "string"/)
  end

  it "fails when attribute does not change" do
    expect do
      expect {}.to change { @instance.some_value }.from("string")
    end.to fail_with(/expected #{value_pattern} to have changed from "string", but did not change/)
  end

  context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description with the block snippet" do
      expect(change { @instance.some_value }.from(3).description).to eq "change `@instance.some_value` from 3"
    end
  end

  context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
    it "provides a #description without the block snippet" do
      expect(change { @instance.some_value }.from(3).description).to eq "change result from 3"
    end
  end

  it "provides a #description" do
    expect(change {}.from(3).description).to eq "change result from 3"
  end
end

RSpec.describe "expect { ... }.to change(actual, message).to(new)" do
  context "with boolean values" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = true
    end

    it "passes when attribute is == to expected value after executing block" do
      expect { @instance.some_value = false }.to change(@instance, :some_value).to(false)
    end

    it "fails when attribute is not == to expected value after executing block" do
      expect do
        expect { @instance.some_value = 1 }.to change(@instance, :some_value).from(true).to(false)
      end.to fail_with("expected `SomethingExpected#some_value` to have changed to false, but is now 1")
    end
  end

  context "with non-boolean values" do
    before(:example) do
      @instance = SomethingExpected.new
      @instance.some_value = 'string'
    end

    it "passes when attribute matches expected value after executing block" do
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value).to("cat")
    end

    it "fails when attribute does not match expected value after executing block" do
      expect do
        expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("string").to("dog")
      end.to fail_with("expected `SomethingExpected#some_value` to have changed to \"dog\", but is now \"cat\"")
    end

    it "fails with a clear message when it ends with the right value but did not change" do
      expect {
        expect {}.to change(@instance, :some_value).to("string")
      }.to fail_with('expected `SomethingExpected#some_value` to have changed to "string", but did not change')
    end
  end
end

RSpec.describe "expect { ... }.to change { block }.to(new)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  it "passes when attribute matches expected value after executing block" do
    expect { @instance.some_value = "cat" }.to change { @instance.some_value }.to("cat")
  end

  it "fails when attribute does not match expected value after executing block" do
    expect do
      expect { @instance.some_value = "cat" }.to change { @instance.some_value }.from("string").to("dog")
    end.to fail_with(/expected #{value_pattern} to have changed to "dog", but is now "cat"/)
  end

  it "provides a #description" do
    expect(change {}.to(3).description).to eq "change result to 3"
  end
end

RSpec.describe "expect { ... }.to change(actual, message).from(old).to(new)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  it "passes when #to comes before #from" do
    expect { @instance.some_value = "cat" }.to change(@instance, :some_value).to("cat").from("string")
  end

  it "passes when #from comes before #to" do
    expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("string").to("cat")
  end

  it "shows the correct messaging when #after and #to are different" do
    expect do
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("string").to("dog")
    end.to fail_with("expected `SomethingExpected#some_value` to have changed to \"dog\", but is now \"cat\"")
  end

  it "shows the correct messaging when #before and #from are different" do
    expect do
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value).from("not_string").to("cat")
    end.to fail_with("expected `SomethingExpected#some_value` to have initially been \"not_string\", but was \"string\"")
  end
end

RSpec.describe "expect { ... }.to change { block }.from(old).to(new)" do
  before(:example) do
    @instance = SomethingExpected.new
    @instance.some_value = 'string'
  end

  context "when #to comes before #from" do
    it "passes" do
      expect { @instance.some_value = "cat" }.to change { @instance.some_value }.to("cat").from("string")
    end

    it "provides a #description" do
      expect(change {}.to(1).from(3).description).to eq "change result to 1 from 3"
    end
  end

  context "when #from comes before #to" do
    it "passes" do
      expect { @instance.some_value = "cat" }.to change { @instance.some_value }.from("string").to("cat")
    end

    it "provides a #description" do
      expect(change {}.from(1).to(3).description).to eq "change result from 1 to 3"
    end
  end
end

RSpec.describe "Composing a matcher with `change`" do
  describe "expect { ... }.to change { ... }" do
    context ".from(matcher).to(matcher)" do
      it 'passes when the matchers match the from and to values' do
        k = 0.51
        expect { k += 1 }.to change { k }.
          from( a_value_within(0.1).of(0.5) ).
          to( a_value_within(0.1).of(1.5) )
      end

      it 'fails with a clear message when the `from` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            from( a_value_within(0.1).of(0.7) ).
            to( a_value_within(0.1).of(1.5) )
        }.to fail_with(/expected #{value_pattern} to have initially been a value within 0.1 of 0.7, but was 0.51/)
      end

      it 'fails with a clear message when the `to` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            from( a_value_within(0.1).of(0.5) ).
            to( a_value_within(0.1).of(2.5) )
        }.to fail_with(/expected #{value_pattern} to have changed to a value within 0.1 of 2.5, but is now 1.51/)
      end

      it 'provides a description' do
        expect(change(nil, :foo).
          from( a_value_within(0.1).of(0.5) ).
          to( a_value_within(0.1).of(1.5) ).description
        ).to eq("change `NilClass#foo` from a value within 0.1 of 0.5 to a value within 0.1 of 1.5")
      end
    end

    context ".to(matcher).from(matcher)" do
      it 'passes when the matchers match the from and to values' do
        k = 0.51
        expect { k += 1 }.to change { k }.
          to( a_value_within(0.1).of(1.5) ).
          from( a_value_within(0.1).of(0.5) )
      end

      it 'fails with a clear message when the `from` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            to( a_value_within(0.1).of(1.5) ).
            from( a_value_within(0.1).of(0.7) )
        }.to fail_with(/expected #{value_pattern} to have initially been a value within 0.1 of 0.7, but was 0.51/)
      end

      it 'fails with a clear message when the `to` does not match' do
        expect {
          k = 0.51
          expect { k += 1 }.to change { k }.
            to( a_value_within(0.1).of(2.5) ).
            from( a_value_within(0.1).of(0.5) )
        }.to fail_with(/expected #{value_pattern} to have changed to a value within 0.1 of 2.5, but is now 1.51/)
      end

      it 'provides a description' do
        expect(change(nil, :foo).
          to( a_value_within(0.1).of(0.5) ).
          from( a_value_within(0.1).of(1.5) ).description
        ).to eq("change `NilClass#foo` to a value within 0.1 of 0.5 from a value within 0.1 of 1.5")
      end
    end

    context ".by(matcher)" do
      it "passes when the matcher matches" do
        k = 0.5
        expect { k += 1.05 }.to change { k }.by( a_value_within(0.1).of(1) )
      end

      it 'fails with a clear message when the `by` does not match' do
        expect {
          k = 0.5
          expect { k += 1.05 }.to change { k }.by( a_value_within(0.1).of(0.5) )
        }.to fail_with(/expected #{value_pattern} to have changed by a value within 0.1 of 0.5, but was changed by 1.05/)
      end

      it 'provides a description' do
        expect(change(nil, :foo).
          by( a_value_within(0.1).of(0.5) ).description
        ).to eq("change `NilClass#foo` by a value within 0.1 of 0.5")
      end
    end
  end

  describe "expect { ... }.not_to change { ... }.from(matcher).to(matcher)" do
    it 'passes when the matcher matches the `from` value and it does not change' do
      k = 0.51
      expect {}.not_to change { k }.from( a_value_within(0.1).of(0.5) )
    end

    it 'fails with a clear message when the `from` matcher does not match' do
      expect {
        k = 0.51
        expect {}.not_to change { k }.from( a_value_within(0.1).of(1.5) )
      }.to fail_with(/expected #{value_pattern} to have initially been a value within 0.1 of 1.5, but was 0.51/)
    end
  end
end

RSpec.describe RSpec::Matchers::BuiltIn::Change do
  it "works when the receiver has implemented #send" do
    @instance = SomethingExpected.new
    @instance.some_value = "string"
    def @instance.send(*_args); raise "DOH! Library developers shouldn't use #send!" end

    expect {
      expect { @instance.some_value = "cat" }.to change(@instance, :some_value)
    }.not_to raise_error
  end

  it_behaves_like "an RSpec block-only matcher" do
    let(:matcher) { change { @k } }
    before { @k = 1 }
    def valid_block
      @k += 1
    end
    def invalid_block
    end
  end
end

RSpec.describe RSpec::Matchers::BuiltIn::ChangeRelatively do
  it_behaves_like "an RSpec block-only matcher", :disallows_negation => true, :skip_deprecation_check => true do
    let(:matcher) { change { @k }.by(1) }
    before { @k = 0 }
    def valid_block
      @k += 1
    end
    def invalid_block
      @k += 2
    end
  end
end

RSpec.describe RSpec::Matchers::BuiltIn::ChangeFromValue do
  it_behaves_like "an RSpec block-only matcher" do
    let(:matcher) { change { @k }.from(0) }
    before { @k = 0 }
    def valid_block
      @k += 1
    end
    def invalid_block
    end
  end
end

RSpec.describe RSpec::Matchers::BuiltIn::ChangeToValue do
  it_behaves_like "an RSpec block-only matcher", :disallows_negation => true do
    let(:matcher) { change { @k }.to(2) }
    before { @k = 0 }
    def valid_block
      @k = 2
    end
    def invalid_block
      @k = 3
    end
  end
end
