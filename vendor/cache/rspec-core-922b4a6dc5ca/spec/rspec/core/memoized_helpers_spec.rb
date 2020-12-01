require 'thread_order'

module RSpec::Core
  RSpec.describe MemoizedHelpers do
    before(:each) { RSpec.configuration.configure_expectation_framework }

    def subject_value_for(describe_arg, &block)
      example_group = RSpec.describe(describe_arg, &block)
      subject_value = nil
      example_group.example { subject_value = subject }
      example_group.run
      subject_value
    end

    describe "implicit subject" do
      describe "with a class" do
        it "returns an instance of the class" do
          expect(subject_value_for(Array)).to eq([])
        end
      end

      describe "with a Module" do
        it "returns the Module" do
          expect(subject_value_for(Enumerable)).to eq(Enumerable)
        end
      end

      describe "with a string" do
        it "returns the string" do
          expect(subject_value_for("Foo")).to eq("Foo")
        end
      end

      describe "with a number" do
        it "returns the number" do
          expect(subject_value_for(15)).to eq(15)
        end
      end

      describe "with a hash" do
        it "returns the hash" do
          expect(subject_value_for(:foo => 3)).to eq(:foo => 3)
        end
      end

      describe "with a symbol" do
        it "returns the symbol" do
          expect(subject_value_for(:foo)).to eq(:foo)
        end
      end

      describe "with true" do
        it "returns `true`" do
          expect(subject_value_for(true)).to eq(true)
        end
      end

      describe "with false" do
        it "returns `false`" do
          expect(subject_value_for(false)).to eq(false)
        end
      end

      describe "with nil" do
        it "returns `nil`" do
          expect(subject_value_for(nil)).to eq(nil)
        end
      end

      it "can be overriden and super'd to from a nested group" do
        outer_subject_value = inner_subject_value = nil

        RSpec.describe(Array) do
          subject { super() << :parent_group }
          example { outer_subject_value = subject }

          context "nested" do
            subject { super() << :child_group }
            example { inner_subject_value = subject }
          end
        end.run

        expect(outer_subject_value).to eq([:parent_group])
        expect(inner_subject_value).to eq([:parent_group, :child_group])
      end
    end

    describe "explicit subject" do
      it "yields the example in which it is eval'd" do
        example_yielded_to_subject = nil
        example_yielded_to_example = nil

        example_group = RSpec.describe
        example_group.subject { |e| example_yielded_to_subject = e }
        example_group.example { |e| subject; example_yielded_to_example = e }
        example_group.run

        expect(example_yielded_to_subject).to eq example_yielded_to_example
      end

      context "doesn't issue a deprecation when used with doubles" do
        subject do
          Struct.new(:value) do
            def working_with?(double)
              double.value >= value
            end
          end.new 1
        end

        it { should be_working_with double(:value => 10) }
      end

      [false, nil].each do |falsy_value|
        context "with a value of #{falsy_value.inspect}" do
          it "is evaluated once per example" do
            subject_calls = 0

            describe_successfully do
              subject { subject_calls += 1; falsy_value }
              example { subject; subject }
            end

            expect(subject_calls).to eq(1)
          end
        end
      end

      describe "defined in a top level group" do
        it "replaces the implicit subject in that group" do
          subject_value = subject_value_for(Array) do
            subject { [1, 2, 3] }
          end
          expect(subject_value).to eq([1, 2, 3])
        end
      end

      describe "defined in a top level group" do
        let(:group) do
          RSpec.describe do
            subject{ [4, 5, 6] }
          end
        end

        it "is available in a nested group (subclass)" do
          subject_value = nil
          group.describe("I'm nested!") do
            example { subject_value = subject }
          end.run

          expect(subject_value).to eq([4, 5, 6])
        end

        it "is available in a doubly nested group (subclass)" do
          subject_value = nil
          group.describe("Nesting level 1") do
            describe("Nesting level 2") do
              example { subject_value = subject }
            end
          end.run

          expect(subject_value).to eq([4, 5, 6])
        end

        it "can be overriden and super'd to from a nested group" do
          subject_value = nil
          group.describe("Nested") do
            subject { super() + [:override] }
            example { subject_value = subject }
          end.run

          expect(subject_value).to eq([4, 5, 6, :override])
        end

        [:before, :after].each do |hook|
          it "raises an error when referenced from `#{hook}(:all)`" do
            result = nil
            line   = nil

            RSpec.describe do
              subject { nil }
              send(hook, :all) { result = (subject rescue $!) }; line = __LINE__
              example { }
            end.run

            expect(result).to be_an(Exception)
            expect(result.message).to match(/subject accessed.*#{hook}\(:context\).*#{__FILE__}:#{line}/m)
          end
        end
      end

      describe "with a name" do
        it "yields the example in which it is eval'd" do
          example_yielded_to_subject = nil
          example_yielded_to_example = nil

          group = RSpec.describe
          group.subject(:foo) { |e| example_yielded_to_subject = e }
          group.example       { |e| foo; example_yielded_to_example = e }
          group.run

          expect(example_yielded_to_subject).to eq example_yielded_to_example
        end

        it "defines a method that returns the memoized subject" do
          list_value_1 = list_value_2 = subject_value_1 = subject_value_2 = nil

          RSpec.describe do
            subject(:list) { [1, 2, 3] }
            example do
              list_value_1 = list
              list_value_2 = list
              subject_value_1 = subject
              subject_value_2 = subject
            end
          end.run

          expect(list_value_1).to eq([1, 2, 3])
          expect(list_value_1).to equal(list_value_2)

          expect(subject_value_1).to equal(subject_value_2)
          expect(subject_value_1).to equal(list_value_1)
        end

        it "is referred from inside subject by the name" do
          inner_subject_value = nil

          RSpec.describe do
            subject(:list) { [1, 2, 3] }
            describe 'first' do
              subject(:first_element) { list.first }
              example { inner_subject_value = subject }
            end
          end.run

          expect(inner_subject_value).to eq(1)
        end

        it 'can continue to be referenced by the name even when an inner group redefines the subject' do
          named_value = nil

          RSpec.describe do
            subject(:named) { :outer }

            describe "inner" do
              subject { :inner }
              example do
                subject # so the inner subject method is run and memoized
                named_value = self.named
              end
            end
          end.run

          expect(named_value).to eq(:outer)
        end

        it 'can continue to reference an inner subject after the outer subject name is referenced' do
          subject_value = nil

          RSpec.describe do
            subject(:named) { :outer }

            describe "inner" do
              subject { :inner }
              example do
                named # so the outer subject method is run and memoized
                subject_value = self.subject
              end
            end
          end.run

          expect(subject_value).to eq(:inner)
        end

        it 'is not overriden when an inner group defines a new method with the same name' do
          subject_value = nil

          RSpec.describe do
            subject(:named) { :outer_subject }

            describe "inner" do
              let(:named) { :inner_named }
              example { subject_value = self.subject }
            end
          end.run

          expect(subject_value).to be(:outer_subject)
        end

        context 'when `super` is used' do
          def should_raise_not_supported_error(&block)
            ex = nil

            RSpec.describe do
              let(:list) { ["a", "b", "c"] }
              subject { [1, 2, 3] }

              describe 'first' do
                module_exec(&block) if block

                subject(:list) { super().first(2) }
                ex = example { subject }
              end
            end.run

            expect(ex.execution_result.status).to eq(:failed)
            expect(ex.execution_result.exception.message).to match(/super.*not supported/)
          end

          it 'raises a "not supported" error' do
            should_raise_not_supported_error
          end

          context 'with a `let` definition before the named subject' do
            it 'raises a "not supported" error' do
              should_raise_not_supported_error do
                # My first pass implementation worked unless there was a `let`
                # declared before the named subject -- this let is in place to
                # ensure that bug doesn't return.
                let(:foo) { 3 }
              end
            end
          end
        end
      end
    end

    context "using 'self' as an explicit subject" do
      it "delegates matcher to the ExampleGroup" do
        group = RSpec.describe("group") do
          subject { self }
          def ok?; true; end
          def not_ok?; false; end

          it { should eq(self) }
          it { should be_ok }
          it { should_not be_not_ok }
        end

        expect(group.run).to be true
      end

      it 'supports a new expect-based syntax' do
        group = RSpec.describe([1, 2, 3]) do
          it { is_expected.to be_an Array }
          it { is_expected.not_to include 4 }
        end

        expect(group.run).to be true
      end
    end

    describe '#subject!' do
      let(:prepared_array) { [1,2,3] }
      subject! { prepared_array.pop }

      it "evaluates subject before example" do
        expect(prepared_array).to eq([1,2])
      end

      it "returns memoized value from first invocation" do
        expect(subject).to eq(3)
      end
    end

    describe 'threadsafety', :threadsafe => true do
      before(:all) { eq 1 } # explanation: https://github.com/rspec/rspec-core/pull/1858/files#r25411166

      context 'when not threadsafe' do
        # would be nice to not set this on the global
        before { RSpec.configuration.threadsafe = false }

        it 'can wind up overwriting the previous memoized value (but if you don\'t need threadsafety, this is faster)' do
          describe_successfully do
            let!(:order) { ThreadOrder.new }
            after { order.apocalypse! :join }

            let :memoized_value do
              if order.current == :second
                :second_access
              else
                order.pass_to :second, :resume_on => :exit
                :first_access
              end
            end

            example do
              order.declare(:second) { expect(memoized_value).to eq :second_access }
              expect(memoized_value).to eq :first_access
            end
          end
        end
      end

      context 'when threadsafe' do
        before(:context) { RSpec.configuration.threadsafe = true }
        specify 'first thread to access determines the return value' do
          describe_successfully do
            let!(:order) { ThreadOrder.new }
            after { order.apocalypse! :join }

            let :memoized_value do
              if order.current == :second
                :second_access
              else
                order.pass_to :second, :resume_on => :sleep
                :first_access
              end
            end

            example do
              order.declare(:second) { expect(memoized_value).to eq :first_access }
              expect(memoized_value).to eq :first_access
            end
          end
        end

        specify 'memoized block will only be evaluated once' do
          describe_successfully do
            let!(:order) { ThreadOrder.new }
            after  { order.apocalypse! }
            before { @previously_accessed = false }

            let :memoized_value do
              raise 'Called multiple times!' if @previously_accessed
              @previously_accessed = true
              order.pass_to :second, :resume_on => :sleep
            end

            example do
              order.declare(:second) { memoized_value }
              memoized_value
              order.join_all
            end
          end
        end

        specify 'memoized blocks prevent other threads from accessing, even when it is accesssed in a superclass' do
          describe_successfully do
            let!(:order) { ThreadOrder.new }
            after { order.apocalypse! :join }

            let!(:calls) { {:parent => 0, :child => 0} }
            let(:memoized_value) do
              calls[:parent] += 1
              order.pass_to :second, :resume_on => :sleep
              'parent'
            end

            describe 'child' do
              let :memoized_value do
                calls[:child] += 1
                "#{super()}/child"
              end

              example do
                order.declare(:second) { expect(memoized_value).to eq 'parent/child' }
                expect(memoized_value).to eq 'parent/child'
                expect(calls).to eq :parent => 1, :child => 1
              end
            end
          end
        end
      end
    end
  end

  RSpec.describe "#let" do
    let(:counter) do
      Class.new do
        def initialize
          @count = 0
        end
        def count
          @count += 1
        end
      end.new
    end

    let(:nil_value) do
      @nil_value_count += 1
      nil
    end

    it "generates an instance method" do
      expect(counter.count).to eq(1)
    end

    it "caches the value" do
      expect(counter.count).to eq(1)
      expect(counter.count).to eq(2)
    end

    it "caches a nil value" do
      @nil_value_count = 0
      nil_value
      nil_value

      expect(@nil_value_count).to eq(1)
    end

    let(:yield_the_example) do |example_yielded_to_let|
      @example_yielded_to_let = example_yielded_to_let
    end

    it "yields the example" do |example_yielded_to_example|
      yield_the_example
      expect(@example_yielded_to_let).to equal example_yielded_to_example
    end

    let(:regex_with_capture) { %r[RegexWithCapture(\d)] }

    it 'does not pass the block up the ancestor chain' do
      # Test for Ruby bug http://bugs.ruby-lang.org/issues/8059
      expect("RegexWithCapture1".match(regex_with_capture)[1]).to eq('1')
    end

    it 'raises a useful error when called without a block' do
      expect do
        RSpec.describe { let(:list) }
      end.to raise_error(/#let or #subject called without a block/)
    end

    it 'raises an error when attempting to define a reserved method name' do
      expect do
        RSpec.describe { let(:initialize) { true }}
      end.to raise_error(/#let or #subject called with a reserved name #initialize/)
    end

    let(:a_value) { "a string" }

    context 'when overriding let in a nested context' do
      let(:a_value) { super() + " (modified)" }

      it 'can use `super` to reference the parent context value' do
        expect(a_value).to eq("a string (modified)")
      end
    end

    context 'when the declaration uses `return`' do
      let(:value) do
        return :early_exit if @early_exit
        :late_exit
      end

      it 'can exit the let declaration early' do
        @early_exit = true
        expect(value).to eq(:early_exit)
      end

      it 'can get past a conditional `return` statement' do
        @early_exit = false
        expect(value).to eq(:late_exit)
      end
    end

    [:before, :after].each do |hook|
      it "raises an error when referenced from `#{hook}(:all)`" do
        result = nil
        line   = nil

        RSpec.describe do
          let(:foo) { nil }
          send(hook, :all) { result = (foo rescue $!) }; line = __LINE__
          example { }
        end.run

        expect(result).to be_an(Exception)
        expect(result.message).to match(/let declaration `foo` accessed.*#{hook}\(:context\).*#{__FILE__}:#{line}/m)
      end
    end

    context "when included modules have hooks that define memoized helpers" do
      it "allows memoized helpers to override methods in previously included modules" do
        group = RSpec.describe do
          include Module.new {
            def self.included(m); m.let(:unrelated) { :unrelated }; end
          }

          include Module.new {
            def hello_message; "Hello from module"; end
          }

          let(:hello_message) { "Hello from let" }
        end

        expect(group.new.hello_message).to eq("Hello from let")
      end
    end
  end

  RSpec.describe "#let!" do
    subject { [1,2,3] }
    let!(:popped) { subject.pop }

    it "evaluates the value non-lazily" do
      expect(subject).to eq([1,2])
    end

    it "returns memoized value from first invocation" do
      expect(popped).to eq(3)
    end
  end

  RSpec.describe 'using subject in before and let blocks' do
    shared_examples_for 'a subject' do
      let(:subject_id_in_let) { subject.object_id }
      before { @subject_id_in_before = subject.object_id }

      it 'should be memoized' do
        expect(subject_id_in_let).to eq(@subject_id_in_before)
      end

      it { is_expected.to eq(subject) }
    end

    describe Object do
      context 'with implicit subject' do
        it_should_behave_like 'a subject'
      end

      context 'with explicit subject' do
        subject { Object.new }
        it_should_behave_like 'a subject'
      end

      context 'with a constant subject'do
        subject { 123 }
        it_should_behave_like 'a subject'
      end
    end
  end

  RSpec.describe 'Module#define_method' do
    it 'retains its normal private visibility on Ruby versions where it is normally private', :if => RUBY_VERSION < '2.5' do
      a_module = Module.new
      expect { a_module.define_method(:name) { "implementation" } }.to raise_error NoMethodError
    end
  end
end

