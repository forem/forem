require 'support/before_all_shared_example_group'

RSpec.describe "Using the legacy should syntax" do
  include_context "with syntax", [:should, :expect]

  describe "#received_message?" do
    let(:dbl) { double("double").as_null_object }

    it "answers false for received_message? when no messages received" do
      expect(dbl.received_message?(:message)).to be_falsey
    end

    it "answers true for received_message? when message received" do
      dbl.message
      expect(dbl.received_message?(:message)).to be_truthy
    end

    it "answers true for received_message? when message received with correct args" do
      dbl.message 1, 2, 3
      expect(dbl.received_message?(:message, 1, 2, 3)).to be_truthy
    end

    it "answers false for received_message? when message received with incorrect args" do
      dbl.message 1, 2, 3
      expect(dbl.received_message?(:message, 1, 2)).to be_falsey
    end
  end

  describe "#stub" do
    it "supports options" do
      double.stub(:foo, :expected_from => "bar")
    end

    it 'returns `nil` from all terminal actions to discourage further configuration' do
      expect(double.stub(:foo).and_return(1)).to be_nil
      expect(double.stub(:foo).and_raise("boom")).to be_nil
      expect(double.stub(:foo).and_throw(:foo)).to be_nil
    end

    it 'sets up a canned response' do
      dbl = double
      dbl.stub(:foo).and_return(3)
      expect(dbl.foo).to eq(3)
    end

    it 'can stub multiple messages using a hash' do
      dbl = double
      dbl.stub(:foo => 2, :bar => 1)
      expect(dbl.foo).to eq(2)
      expect(dbl.bar).to eq(1)
    end

    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        Object.stub(:foo)
      end
    end
  end

  describe "#stub_chain" do
    it 'can stub a sequence of messages' do
      dbl = double
      dbl.stub_chain(:foo, :bar, :baz => 17)
      expect(dbl.foo.bar.baz).to eq(17)
      expect {
        dbl.foo.baz.bar
      }.to fail
    end

    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        Object.stub_chain(:foo, :bar)
      end
    end
  end

  describe "#unstub" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        Object.unstub(:foo)
      end
    end

    it "replaces the stubbed method with the original method" do
      obj = Object.new
      def obj.foo; :original; end
      obj.stub(:foo)
      obj.unstub(:foo)
      expect(obj.foo).to eq :original
    end

    it "removes all stubs with the supplied method name" do
      obj = Object.new
      def obj.foo; :original; end
      obj.stub(:foo).with(1)
      obj.stub(:foo).with(2)
      obj.unstub(:foo)
      expect(obj.foo).to eq :original
    end

    it "does not remove any expectations with the same method name" do
      obj = Object.new
      def obj.foo; :original; end
      obj.should_receive(:foo).with(3).and_return(:three)
      obj.stub(:foo).with(1)
      obj.stub(:foo).with(2)
      obj.unstub(:foo)
      expect(obj.foo(3)).to eq :three
    end

    it "restores the correct implementations when stubbed and unstubbed on a parent and child class" do
      parent = Class.new
      child  = Class.new(parent)

      parent.stub(:new)
      child.stub(:new)
      parent.unstub(:new)
      child.unstub(:new)

      expect(parent.new).to be_an_instance_of parent
      expect(child.new).to be_an_instance_of child
    end

    it "raises a MockExpectationError if the method has not been stubbed" do
      obj = Object.new
      expect {
        obj.unstub(:foo)
      }.to fail
    end
  end

  describe "#should_receive" do
    it 'fails on verification if the message is not received' do
      dbl = double
      dbl.should_receive(:foo)
      expect { verify_all }.to fail
    end

    it 'does not fail on verification if the message is received' do
      dbl = double
      dbl.should_receive(:foo)
      dbl.foo
      expect { verify_all }.not_to raise_error
    end

    it 'can set a canned response' do
      dbl = double
      dbl.should_receive(:bar).and_return(3)
      expect(dbl.bar).to eq(3)
    end

    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        Object.should_receive(:foo)
      end
    end

    context "with an options hash" do
      it "reports the file and line submitted with :expected_from" do
        begin
          mock = RSpec::Mocks::Double.new("a mock")
          mock.should_receive(:message, :expected_from => "/path/to/blah.ext:37")
          verify mock
        rescue Exception => e
        ensure
          expect(e.backtrace.to_s).to match(%r{/path/to/blah.ext:37}m)
        end
      end

      it "uses the message supplied with :message" do
        expect {
          m = RSpec::Mocks::Double.new("a mock")
          m.should_receive(:message, :message => "recebi nada")
          verify m
        }.to raise_error("recebi nada")
      end

      it "uses the message supplied with :message after a similar stub" do
        expect {
          m = RSpec::Mocks::Double.new("a mock")
          m.stub(:message)
          m.should_receive(:message, :message => "from mock")
          verify m
        }.to raise_error("from mock")
      end
    end
  end

  describe "#should_not_receive" do
    it "returns a negative message expectation" do
      expect(Object.new.should_not_receive(:foobar)).to be_negative
    end

    it 'fails when the message is received' do
      with_unfulfilled_double do |dbl|
        dbl.should_not_receive(:foo)
        expect { dbl.foo }.to fail
      end
    end

    it 'does not fail on verification if the message is not received' do
      dbl = double
      dbl.should_not_receive(:foo)
      expect { verify_all }.not_to raise_error
    end

    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        Object.should_not_receive(:foo)
      end
    end
  end

  describe "#any_instance" do
    let(:klass) do
      Class.new do
        def existing_method; :existing_method_return_value; end
        def existing_method_with_arguments(_a, _b=nil); :existing_method_with_arguments_return_value; end
        def another_existing_method; end
      private
        def private_method; :private_method_return_value; end
      end
    end

    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        Object.any_instance.should_receive(:foo)
      end
    end

    it "adds a class to the current space" do
      expect {
        klass.any_instance
      }.to change { RSpec::Mocks.space.any_instance_recorders.size }.by(1)
    end

    it 'can stub a method' do
      klass.any_instance.stub(:foo).and_return(2)
      expect(klass.new.foo).to eq(2)
    end

    it 'can mock a method' do
      klass.any_instance.should_receive(:foo)
      klass.new
      expect { verify_all }.to fail
    end

    it 'can get method objects for the fluent interface', :if => RUBY_VERSION.to_f > 1.8 do
      and_return = klass.any_instance.stub(:foo).method(:and_return)
      and_return.call(23)

      expect(klass.new.foo).to eq(23)
    end

    it 'affects previously stubbed instances when stubbing a method' do
      instance = klass.new
      klass.any_instance.stub(:foo).and_return(2)
      expect(instance.foo).to eq(2)
      klass.any_instance.stub(:foo).and_return(1)
      expect(instance.foo).to eq(1)
    end

    it 'affects previously stubbed instances when mocking a method' do
      instance = klass.new
      klass.any_instance.stub(:foo).and_return(2)
      expect(instance.foo).to eq(2)
      klass.any_instance.should_receive(:foo).and_return(1)
      expect(instance.foo).to eq(1)
    end

    context "invocation order" do
      describe "#stub" do
        it "raises an error if 'stub' follows 'with'" do
          expect { klass.any_instance.with("1").stub(:foo) }.to raise_error(NoMethodError)
        end

        it "raises an error if 'with' follows 'and_return'" do
          expect { klass.any_instance.stub(:foo).and_return(1).with("1") }.to raise_error(NoMethodError)
        end

        it "raises an error if 'with' follows 'and_raise'" do
          expect { klass.any_instance.stub(:foo).and_raise(1).with("1") }.to raise_error(NoMethodError)
        end

        it "raises an error if 'with' follows 'and_yield'" do
          expect { klass.any_instance.stub(:foo).and_yield(1).with("1") }.to raise_error(NoMethodError)
        end

        context "behaves as 'every instance'" do
          let(:super_class) { Class.new { def foo; 'bar'; end } }
          let(:sub_class)   { Class.new(super_class) }

          it 'handles `unstub` on subclasses' do
            super_class.any_instance.stub(:foo)
            sub_class.any_instance.stub(:foo)
            sub_class.any_instance.unstub(:foo)
            expect(sub_class.new.foo).to eq("bar")
          end
        end
      end

      describe "#stub_chain" do
        it "raises an error if 'stub_chain' follows 'and_return'" do
          expect { klass.any_instance.and_return("1").stub_chain(:foo, :bar) }.to raise_error(NoMethodError)
        end

        context "allows a chain of methods to be stubbed using #stub_chain" do
          example "given symbols representing the methods" do
            klass.any_instance.stub_chain(:one, :two, :three).and_return(:four)
            expect(klass.new.one.two.three).to eq(:four)
          end

          example "given a hash as the last argument uses the value as the expected return value" do
            klass.any_instance.stub_chain(:one, :two, :three => :four)
            expect(klass.new.one.two.three).to eq(:four)
          end

          example "given a string of '.' separated method names representing the chain" do
            klass.any_instance.stub_chain('one.two.three').and_return(:four)
            expect(klass.new.one.two.three).to eq(:four)
          end
        end

        it 'affects previously stubbed instances' do
          instance = klass.new
          dbl = double
          klass.any_instance.stub(:foo).and_return(dbl)
          expect(instance.foo).to eq(dbl)
          klass.any_instance.stub_chain(:foo, :bar => 3)
          expect(instance.foo.bar).to eq(3)
        end
      end

      describe "#should_receive" do
        it "raises an error if 'should_receive' follows 'with'" do
          expect { klass.any_instance.with("1").should_receive(:foo) }.to raise_error(NoMethodError)
        end
      end

      describe "#should_not_receive" do
        it "fails if the method is called" do
          klass.any_instance.should_not_receive(:existing_method)
          instance = klass.new
          expect_fast_failure_from(instance) do
            instance.existing_method
          end
        end

        it "passes if no method is called" do
          expect { klass.any_instance.should_not_receive(:existing_method) }.to_not raise_error
        end

        it "passes if only a different method is called" do
          klass.any_instance.should_not_receive(:existing_method)
          expect { klass.new.another_existing_method }.to_not raise_error
        end

        context "with constraints" do
          it "fails if the method is called with the specified parameters" do
            klass.any_instance.should_not_receive(:existing_method_with_arguments).with(:argument_one, :argument_two)
            instance = klass.new
            expect_fast_failure_from(instance) do
              instance.existing_method_with_arguments(:argument_one, :argument_two)
            end
          end

          it "passes if the method is called with different parameters" do
            klass.any_instance.should_not_receive(:existing_method_with_arguments).with(:argument_one, :argument_two)
            expect { klass.new.existing_method_with_arguments(:argument_three, :argument_four) }.to_not raise_error
          end
        end

        context 'when used in combination with should_receive' do
          it 'passes if only the expected message is received' do
            klass.any_instance.should_receive(:foo)
            klass.any_instance.should_not_receive(:bar)
            klass.new.foo
            verify_all
          end
        end

        it "prevents confusing double-negative expressions involving `never`" do
          expect {
            klass.any_instance.should_not_receive(:not_expected).never
          }.to raise_error(/trying to negate it again/)
        end
      end

      describe "#unstub" do
        it "replaces the stubbed method with the original method" do
          klass.any_instance.stub(:existing_method)
          klass.any_instance.unstub(:existing_method)
          expect(klass.new.existing_method).to eq(:existing_method_return_value)
        end

        it "removes all stubs with the supplied method name" do
          klass.any_instance.stub(:existing_method).with(1)
          klass.any_instance.stub(:existing_method).with(2)
          klass.any_instance.unstub(:existing_method)
          expect(klass.new.existing_method).to eq(:existing_method_return_value)
        end

        it "removes stubs even if they have already been invoked" do
          klass.any_instance.stub(:existing_method).and_return(:any_instance_value)
          obj = klass.new
          obj.existing_method
          klass.any_instance.unstub(:existing_method)
          expect(obj.existing_method).to eq(:existing_method_return_value)
        end

        it "removes stubs from sub class after invokation when super class was originally stubbed" do
          klass.any_instance.stub(:existing_method).and_return(:any_instance_value)
          obj = Class.new(klass).new
          expect(obj.existing_method).to eq(:any_instance_value)
          klass.any_instance.unstub(:existing_method)
          expect(obj.existing_method).to eq(:existing_method_return_value)
        end

        it "removes stubs set directly on an instance" do
          klass.any_instance.stub(:existing_method).and_return(:any_instance_value)
          obj = klass.new
          obj.stub(:existing_method).and_return(:local_method)
          klass.any_instance.unstub(:existing_method)
          expect(obj.existing_method).to eq(:existing_method_return_value)
        end

        it "does not remove message expectations set directly on an instance" do
          klass.any_instance.stub(:existing_method).and_return(:any_instance_value)
          obj = klass.new
          obj.should_receive(:existing_method).and_return(:local_method)
          klass.any_instance.unstub(:existing_method)
          expect(obj.existing_method).to eq(:local_method)
        end

        it "does not remove any expectations with the same method name" do
          klass.any_instance.should_receive(:existing_method_with_arguments).with(3).and_return(:three)
          klass.any_instance.stub(:existing_method_with_arguments).with(1)
          klass.any_instance.stub(:existing_method_with_arguments).with(2)
          klass.any_instance.unstub(:existing_method_with_arguments)
          expect(klass.new.existing_method_with_arguments(3)).to eq(:three)
        end

        it "raises a MockExpectationError if the method has not been stubbed" do
          expect {
            klass.any_instance.unstub(:existing_method)
          }.to fail_with 'The method `existing_method` was not stubbed or was already unstubbed'
        end

        it 'does not get confused about string vs symbol usage for the message' do
          klass.any_instance.stub(:existing_method) { :stubbed }
          klass.any_instance.unstub("existing_method")
          expect(klass.new.existing_method).to eq(:existing_method_return_value)
        end
      end
    end
  end
end

RSpec.context "with default syntax configuration" do
  orig_syntax = nil

  before(:all) { orig_syntax = RSpec::Mocks.configuration.syntax }
  after(:all)  { RSpec::Mocks.configuration.syntax = orig_syntax }
  before       { RSpec::Mocks.configuration.reset_syntaxes_to_default }

  if RSpec::Support::RubyFeatures.required_kw_args_supported?
    let(:expected_arguments) {
      [
        /Using.*without explicitly enabling/,
      ]
    }
    let(:expected_keywords) {
      {:replacement => "the new `:expect` syntax or explicitly enable `:should`"}
    }
    it "it warns about should once, regardless of how many times it is called" do
      # Use eval to avoid syntax error on 1.8 and 1.9
      eval("expect(RSpec).to receive(:deprecate).with(*expected_arguments, **expected_keywords)")
      o = Object.new
      o2 = Object.new
      o.should_receive(:bees)
      o2.should_receive(:bees)

      o.bees
      o2.bees
    end

    it "warns about should not once, regardless of how many times it is called" do
      # Use eval to avoid syntax error on 1.8 and 1.9
      eval("expect(RSpec).to receive(:deprecate).with(*expected_arguments, **expected_keywords)")
      o = Object.new
      o2 = Object.new
      o.should_not_receive(:bees)
      o2.should_not_receive(:bees)
    end

    it "warns about stubbing once, regardless of how many times it is called" do
      # Use eval to avoid syntax error on 1.8 and 1.9
      eval("expect(RSpec).to receive(:deprecate).with(*expected_arguments, **expected_keywords)")
      o = Object.new
      o2 = Object.new

      o.stub(:faces)
      o2.stub(:faces)
    end
  else
    let(:expected_arguments) {
      [
        /Using.*without explicitly enabling/,
        {:replacement => "the new `:expect` syntax or explicitly enable `:should`"}
      ]
    }
    it "it warns about should once, regardless of how many times it is called" do
      expect(RSpec).to receive(:deprecate).with(*expected_arguments)
      o = Object.new
      o2 = Object.new
      o.should_receive(:bees)
      o2.should_receive(:bees)

      o.bees
      o2.bees
    end

    it "warns about should not once, regardless of how many times it is called" do
      expect(RSpec).to receive(:deprecate).with(*expected_arguments)
      o = Object.new
      o2 = Object.new
      o.should_not_receive(:bees)
      o2.should_not_receive(:bees)
    end

    it "warns about stubbing once, regardless of how many times it is called" do
      expect(RSpec).to receive(:deprecate).with(*expected_arguments)
      o = Object.new
      o2 = Object.new

      o.stub(:faces)
      o2.stub(:faces)
    end
  end

  it "warns about unstubbing once, regardless of how many times it is called" do
    expect(RSpec).to receive(:deprecate).with(/Using.*without explicitly enabling/,
      :replacement => "`allow(...).to receive(...).and_call_original` or explicitly enable `:should`")
    o = Object.new
    o2 = Object.new

    allow(o).to receive(:faces)
    allow(o2).to receive(:faces)

    o.unstub(:faces)
    o2.unstub(:faces)
  end

  it "doesn't warn about stubbing after a reset and setting should" do
    expect(RSpec).not_to receive(:deprecate)
    RSpec::Mocks.configuration.reset_syntaxes_to_default
    RSpec::Mocks.configuration.syntax = :should
    o = Object.new
    o2 = Object.new
    o.stub(:faces)
    o2.stub(:faces)
  end

  it "includes the call site in the deprecation warning" do
    obj = Object.new
    expect_deprecation_with_call_site(__FILE__, __LINE__ + 1)
    obj.stub(:faces)
  end
end

RSpec.context "when the should syntax is enabled on a non-default syntax host" do
  include_context "with the default mocks syntax"

  it "continues to warn about the should syntax" do
    my_host = Class.new
    expect(RSpec).to receive(:deprecate)
    RSpec::Mocks::Syntax.enable_should(my_host)

    o = Object.new
    o.should_receive(:bees)
    o.bees
  end
end
