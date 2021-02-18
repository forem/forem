module RSpec
  module Mocks
    RSpec.describe "A partial double" do
      let(:object) { Object.new }

      it 'does not create an any_instance recorder when a message is allowed' do
        expect {
          allow(object).to receive(:foo)
        }.not_to change { RSpec::Mocks.space.any_instance_recorders }.from({})
      end

      it "names the class in the failure message" do
        expect(object).to receive(:foo)
        expect do
          verify object
        end.to fail_with(/\(#<Object:.*>\).foo/)
      end

      it "names the class in the failure message when expectation is on class" do
        expect(Object).to receive(:foo)
        expect {
          verify Object
        }.to fail_with(/Object \(class\)/)
      end

      it "does not conflict with @options in the object" do
        object.instance_exec { @options = Object.new }
        expect(object).to receive(:blah)
        object.blah
      end

      it 'allows `class` to be stubbed even when `any_instance` has already been used' do
        # See https://github.com/rspec/rspec-mocks/issues/687
        # The infinite recursion code path was only triggered when there were
        # active any instance recorders in the current example, so we make one here.
        allow_any_instance_of(Object).to receive(:bar).and_return(2)

        expect(object.class).not_to eq(String)
        allow(object).to receive_messages(:foo => 1, :class => String)

        expect(object.foo).to eq(1)
        expect(object.class).to eq(String)
        expect(object.bar).to eq(2)
      end

      it 'allows `respond_to?` to be stubbed' do
        the_klass = Class.new do
          def call(name)
            if respond_to?(name)
              send(name)
            end
          end
        end

        an_object = the_klass.new

        expect(an_object).to receive(:respond_to?).
                               with(:my_method).at_least(:once) { true }
        expect(an_object).to receive(:my_method)

        an_object.call :my_method
      end

      it "can disallow messages from being received" do
        expect(object).not_to receive(:fuhbar)
        expect_fast_failure_from(
          object,
          /expected\: 0 times with any arguments\n    received\: 1 time/
        ) do
          object.fuhbar
        end
      end

      it "can expect a message and set a return value" do
        expect(object).to receive(:foobar).with(:test_param).and_return(1)
        expect(object.foobar(:test_param)).to equal(1)
      end

      it "can accept a hash as a message argument" do
        expect(object).to receive(:foobar).with(:key => "value").and_return(1)
        expect(object.foobar(:key => "value")).to equal(1)
      end

      if RSpec::Support::RubyFeatures.required_kw_args_supported?
        # Use eval to avoid syntax error on 1.8 and 1.9
        binding.eval(<<-CODE, __FILE__, __LINE__)
        it "can accept an inner hash as a message argument" do
          hash = {:a => {:key => "value"}}
          expect(object).to receive(:foobar).with(:key => "value").and_return(1)
          expect(object.foobar(**hash[:a])).to equal(1)
        end
        CODE
      end

      it "can create a positive message expectation" do
        expect(expect(object).to receive(:foobar)).not_to be_negative
        object.foobar
      end

      it 'allows a class and a subclass to both be stubbed' do
        pending "Does not work on 1.8.7 due to singleton method restrictions" if RUBY_VERSION == "1.8.7" && RSpec::Support::Ruby.mri?
        the_klass = Class.new
        the_subklass = Class.new(the_klass)

        allow(the_klass).to receive(:foo).and_return(1)
        allow(the_subklass).to receive(:foo).and_return(2)

        expect(the_klass.foo).to eq(1)
        expect(the_subklass.foo).to eq(2)
      end

      it "verifies the method was called when expecting a message" do
        expect(object).to receive(:foobar).with(:test_param).and_return(1)
        expect {
          verify object
        }.to fail
      end

      it "can accept the string form of a message for a positive message expectation" do
        expect(object).to receive('foobar')
        object.foobar
      end

      it "can accept the string form of a message for a negative message expectation" do
        expect(object).not_to receive('foobar')

        expect_fast_failure_from(object) do
          object.foobar
        end
      end

      it "uses reports nil in the error message" do
        allow_message_expectations_on_nil

        nil_var = nil
        expect(nil_var).to receive(:foobar)
        expect {
          verify nil_var
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          %Q|(nil).foobar(*(any args))\n    expected: 1 time with any arguments\n    received: 0 times with any arguments|
        )
      end

      it "includes the class name in the error when mocking a class method that is called an extra time with the wrong args" do
        klazz = Class.new do
          def self.inspect
            "MyClass"
          end
        end

        expect(klazz).to receive(:bar).with(1)
        klazz.bar(1)

        expect {
          klazz.bar(2)
        }.to fail_with(/MyClass/)
      end

      it "shares message expectations with clone" do
        expect(object).to receive(:foobar)
        twin = object.clone
        twin.foobar
        expect { verify twin }.not_to raise_error
        expect { verify object }.not_to raise_error
      end

      it "clears message expectations when `dup`ed" do
        expect(object).to receive(:foobar)
        duplicate = object.dup
        expect { duplicate.foobar }.to raise_error(NoMethodError, /foobar/)
        expect { verify object }.to fail_with(/foobar/)
      end
    end

    RSpec.describe "Using a reopened file object as a partial mock" do
      let(:file_1) { File.open(File.join("tmp", "file_1"), "w").tap { |f| f.sync = true } }
      let(:file_2) { File.open(File.join("tmp", "file_2"), "w").tap { |f| f.sync = true } }

      def read_file(file)
        File.open(file.path, "r", &:read)
      end

      after do
        file_1.close
        file_2.close
      end

      def expect_output_warning_on_ruby_lt_2
        if RUBY_VERSION >= '2.0'
          yield
        else
          expect { yield }.to output(a_string_including(
            "RSpec could not fully restore", file_1.inspect, "write"
          )).to_stderr
        end
      end

      it "allows `write` to be stubbed and reset", :unless => Support::Ruby.jruby? do
        allow(file_1).to receive(:write)
        file_1.reopen(file_2)
        expect_output_warning_on_ruby_lt_2 { reset file_1 }

        expect {
          # Writing to a file that's been reopened to a 2nd file writes to both files.
          file_1.write("foo")
        }.to change  { read_file(file_1) }.from("").to("foo").
          and change { read_file(file_2) }.from("").to("foo")
      end
    end

    RSpec.describe "Using a partial mock on a proxy object", :if => defined?(::BasicObject) do
      let(:proxy_class) do
        Class.new(::BasicObject) do
          def initialize(target)
            @target = target
          end

          def proxied?
            true
          end

          def respond_to?(name, include_all=false)
            super || name == :proxied? || @target.respond_to?(name, include_all)
          end

          def method_missing(*a)
            @target.send(*a)
          end
        end
      end

      let(:wrapped_object) { Object.new }
      let(:proxy) { proxy_class.new(wrapped_object) }

      it 'works properly' do
        expect(proxy).to receive(:proxied?).and_return(false)
        expect(proxy).not_to be_proxied
      end

      it 'does not confuse the proxy and the proxied object' do
        allow(proxy).to receive(:foo).and_return(:proxy_foo)
        allow(wrapped_object).to receive(:foo).and_return(:wrapped_foo)

        expect(proxy.foo).to eq(:proxy_foo)
        expect(wrapped_object.foo).to eq(:wrapped_foo)
      end
    end

    RSpec.describe "Partially mocking an object that defines ==, after another mock has been defined" do
      before(:each) do
        double("existing mock", :foo => :foo)
      end

      let(:klass) do
        Class.new do
          attr_reader :val
          def initialize(val)
            @val = val
          end

          def ==(other)
            @val == other.val
          end
        end
      end

      it "does not raise an error when stubbing the object" do
        o = klass.new :foo
        expect { allow(o).to receive(:bar) }.not_to raise_error
      end
    end

    RSpec.describe "A partial class mock that has been subclassed" do
      let(:klass)  { Class.new }
      let(:subklass) { Class.new(klass) }

      it "cleans up stubs during #reset to prevent leakage onto subclasses between examples" do
        allow(klass).to receive(:new).and_return(:new_foo)
        expect(subklass.new).to eq :new_foo

        reset(klass)

        expect(subklass.new).to be_a(subklass)
      end

      describe "stubbing a base class class method" do
        before do
          allow(klass).to receive(:find).and_return "stubbed_value"
        end

        it "returns the value for the stub on the base class" do
          expect(klass.find).to eq "stubbed_value"
        end

        it "returns the value for the descendent class" do
          expect(subklass.find).to eq "stubbed_value"
        end
      end
    end

    RSpec.describe "Method visibility when using partial mocks" do
      let(:klass) do
        Class.new do
          def public_method
            private_method
            protected_method
          end
        protected
          def protected_method; end
        private
          def private_method; end
        end
      end

      let(:object) { klass.new }

      it 'keeps public methods public' do
        expect(object).to receive(:public_method)
        expect(object.public_methods).to include_method(:public_method)
        object.public_method
      end

      it 'keeps private methods private' do
        expect(object).to receive(:private_method)
        expect(object.private_methods).to include_method(:private_method)
        object.public_method
      end

      it 'keeps protected methods protected' do
        expect(object).to receive(:protected_method)
        expect(object.protected_methods).to include_method(:protected_method)
        object.public_method
      end
    end

    RSpec.describe 'when verify_partial_doubles configuration option is set' do
      include_context "with isolated configuration"

      let(:klass) do
        Class.new do
          def implemented
            "works"
          end

          def initialize(_a, _b)
          end

          def respond_to?(method_name, include_all=false)
            method_name.to_s == "dynamic_method" || super
          end

          def method_missing(method_name, *args)
            if respond_to?(method_name)
              method_name
            else
              super
            end
          end

        private

          def defined_private_method
            "works"
          end
        end
      end

      let(:object) { klass.new(1, 2) }

      before do
        RSpec::Mocks.configuration.verify_partial_doubles = true
      end

      it 'allows valid methods to be expected' do
        expect(object).to receive(:implemented).and_call_original
        expect(object.implemented).to eq("works")
      end

      it 'allows private methods to be expected' do
        expect(object).to receive(:defined_private_method).and_call_original
        expect(object.send(:defined_private_method)).to eq("works")
      end

      it 'can be temporarily supressed' do
        without_partial_double_verification do
          expect(object).to receive(:fictitious_method) { 'works' }
          expect_any_instance_of(klass).to receive(:other_fictitious_method) { 'works' }
        end
        expect(object.fictitious_method).to eq 'works'
        expect(object.other_fictitious_method).to eq 'works'

        expect {
          expect(object).to receive(:another_fictitious_method) { 'works' }
        }.to raise_error RSpec::Mocks::MockExpectationError
      end

      it 'can be temporarily supressed and nested' do
        without_partial_double_verification do
          without_partial_double_verification do
            expect(object).to receive(:fictitious_method) { 'works' }
          end
          expect(object).to receive(:other_fictitious_method) { 'works' }
        end
        expect(object.fictitious_method).to eq 'works'
        expect(object.other_fictitious_method).to eq 'works'

        expect {
          expect(object).to receive(:another_fictitious_method) { 'works' }
        }.to raise_error RSpec::Mocks::MockExpectationError
      end

      specify 'temporarily supressing partial doubles does not affect normal verifying doubles' do
        without_partial_double_verification do
          expect {
            instance_double(Class.new, :fictitious_method => 'works')
          }.to raise_error RSpec::Mocks::MockExpectationError
        end
      end

      it 'runs the before_verifying_double callbacks before verifying an expectation' do
        expect { |probe|
          RSpec.configuration.mock_with(:rspec) do |config|
            config.before_verifying_doubles(&probe)
          end

          expect(object).to receive(:implemented)
        }.to yield_with_args(have_attributes :target => object)
        object.implemented
      end

      it 'runs the before_verifying_double callbacks before verifying an allowance' do
        expect { |probe|
          RSpec.configuration.mock_with(:rspec) do |config|
            config.before_verifying_doubles(&probe)
          end

          allow(object).to receive(:implemented)
        }.to yield_with_args(have_attributes :target => object)
        object.implemented
      end

      it 'avoids deadlocks when a proxy is accessed from within a `before_verifying_doubles` callback' do
        msg_klass = Class.new { def message; end; }
        called_for = []

        RSpec.configuration.mock_with(:rspec) do |config|
          config.before_verifying_doubles do |ref|
            unless called_for.include? ref.target
              called_for << ref.target
              ::RSpec::Mocks.space.proxy_for(ref.target)
            end
          end
        end

        expect { allow(msg_klass.new).to receive(:message) }.to_not raise_error
      end

      context "for a class" do
        let(:subclass) { Class.new(klass) }

        it "only runs the `before_verifying_doubles` callback for the class (not for superclasses)" do
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.before_verifying_doubles(&probe)
            end

            allow(subclass).to receive(:new)
          }.to yield_successive_args(
            an_object_having_attributes(:target => subclass)
          )
        end

        it 'can be temporarily supressed' do
          without_partial_double_verification do
            expect(subclass).to receive(:fictitious_method) { 'works' }
          end
          expect(subclass.fictitious_method).to eq 'works'

          expect {
            expect(subclass).to receive(:another_fictitious_method) { 'works' }
          }.to raise_error RSpec::Mocks::MockExpectationError
        end

      end

      it 'does not allow a non-existing method to be expected' do
        prevents { expect(object).to receive(:unimplemented) }
      end

      it 'does not allow a spy on unimplemented method' do
        prevents(/does not implement/) {
          expect(object).to have_received(:unimplemented)
        }
      end

      it 'verifies arity range when matching arguments' do
        prevents { expect(object).to receive(:implemented).with('bogus') }
        reset object
      end

      it 'allows a method defined with method_missing to be expected' do
        expect(object).to receive(:dynamic_method).with('a').and_call_original
        expect(object.dynamic_method('a')).to eq(:dynamic_method)
      end

      it 'allows valid methods to be expected on any_instance' do
        expect_any_instance_of(klass).to receive(:implemented)
        object.implemented
      end

      it 'allows private methods to be expected on any_instance expectation' do
        expect_any_instance_of(klass).to receive(:defined_private_method).and_call_original
        object.send(:defined_private_method)
      end

      it 'runs the before_verifying_double callbacks on any_instance before verifying a double allowance' do
        expect_any_instance_of(klass).to receive(:implemented)

        expect { |probe|
          RSpec.configuration.mock_with(:rspec) do |config|
            config.before_verifying_doubles(&probe)
          end

          object.implemented
        }.to yield_with_args(have_attributes :target => klass)
      end

      it 'runs the before_verifying_double callbacks on any_instance before verifying a double' do
        allow_any_instance_of(klass).to receive(:implemented)

        expect { |probe|
          RSpec.configuration.mock_with(:rspec) do |config|
            config.before_verifying_doubles(&probe)
          end

          object.implemented
        }.to yield_with_args(have_attributes :target => klass)
      end

      it 'does not allow a non-existing method to be called on any_instance' do
        prevents(/does not implement/) {
          expect_any_instance_of(klass).to receive(:unimplemented)
        }
      end

      it 'does not allow missing methods to be called on any_instance' do
        # This is potentially surprising behaviour, but there is no way for us
        # to know that this method is valid since we only have class and not an
        # instance.
        prevents(/does not implement/) {
          expect_any_instance_of(klass).to receive(:dynamic_method)
        }
      end

      it 'verifies arity range when receiving a message' do
        allow(object).to receive(:implemented)
        expect {
          object.implemented('bogus')
        }.to raise_error(
          ArgumentError,
          a_string_including("Wrong number of arguments. Expected 0, got 1.")
        )
      end

      it 'allows the mock to raise an error with yield' do
        sample_error = Class.new(StandardError)
        expect(object).to receive(:implemented) { raise sample_error }
        expect { object.implemented }.to raise_error(sample_error)
      end

      it 'allows stubbing and calls the stubbed implementation' do
        allow(object).to receive(:implemented) { :value }
        expect(object.implemented).to eq(:value)
      end

      context "when `.new` is stubbed" do
        before do
          expect(klass.instance_method(:initialize).arity).to eq(2)
        end

        it 'uses the method signature from `#initialize` for arg verification' do
          prevents(/arguments/) { allow(klass).to receive(:new).with(1) }
          allow(klass).to receive(:new).with(1, 2)
        end

        context "on a class that has redefined `new`" do
          it "uses the method signature of the redefined `new` for arg verification" do
            subclass = Class.new(klass) do
              def self.new(_); end
            end

            prevents(/arguments/) { allow(subclass).to receive(:new).with(1, 2) }
            allow(subclass).to receive(:new).with(1)
          end
        end

        context "on a class that has undefined `new`" do
          it "prevents it from being stubbed" do
            subclass = Class.new(klass) do
              class << self
                undef new
              end
            end

            prevents(/does not implement/) { allow(subclass).to receive(:new).with(1, 2) }
          end
        end

        context "on a class with a private `new`" do
          it 'uses the method signature from `#initialize` for arg verification' do
            if RSpec::Support::Ruby.jruby? && RSpec::Support::Ruby.jruby_version < '9.2.1.0'
              pending "Failing on JRuby due to https://github.com/jruby/jruby/issues/2565"
            end

            subclass = Class.new(klass) do
              private_class_method :new
            end

            prevents(/arguments/) { allow(subclass).to receive(:new).with(1) }
            allow(subclass).to receive(:new).with(1, 2)
          end
        end

        context 'on a class that has redefined `self.method`' do
          it 'allows the stubbing of :new' do
            subclass = Class.new(klass) do
              def self.method(*); end
            end

            allow(subclass).to receive(:new)
          end
        end
      end
    end
  end
end
