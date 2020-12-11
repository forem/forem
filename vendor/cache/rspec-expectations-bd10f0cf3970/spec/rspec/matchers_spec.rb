main = self
RSpec.describe RSpec::Matchers do
  include ::RSpec::Support::InSubProcess

  describe ".configuration" do
    it 'returns a memoized configuration instance' do
      expect(RSpec::Matchers.configuration).to be_a(RSpec::Expectations::Configuration)
      expect(RSpec::Matchers.configuration).to be(RSpec::Matchers.configuration)
    end
  end

  it 'can be mixed into `main`' do
    in_sub_process do
      allow_warning if RSpec::Support::Ruby.mri? && RUBY_VERSION[0, 3] == '1.9'

      main.instance_eval do
        include RSpec::Matchers
        include RSpec::Matchers::FailMatchers

        expect(3).to eq(3)
        expect(3).to be_odd

        expect {
          expect(4).to be_zero
        }.to fail_with("expected `4.zero?` to return true, got false")
      end
    end
  end

  context "when included into a superclass after a subclass has already included it" do
    if RSpec::Support::Ruby.mri? && RUBY_VERSION[0, 3] == '1.9'
      desc_start = "print"
      matcher_method = :output
    else
      desc_start = "does not print"
      matcher_method = :avoid_outputting
    end

    it "#{desc_start} a warning so the user is made aware of the MRI 1.9 bug that can cause infinite recursion" do
      superclass = stub_const("Superclass", Class.new)
      stub_const("Subclass", Class.new(superclass) { include RSpec::Matchers })

      expect {
        superclass.send(:include, RSpec::Matchers)
      }.to send(matcher_method, a_string_including(
        "Superclass", "Subclass", "has been included"
      )).to_stderr
    end

    it "does not warn when this is a re-inclusion" do
      superclass = stub_const("Superclass", Class.new { include RSpec::Matchers })
      stub_const("Subclass", Class.new(superclass) { include RSpec::Matchers })

      expect {
        superclass.send(:include, RSpec::Matchers)
      }.to avoid_outputting.to_stderr
    end
  end

  describe "#respond_to?" do
    it "handles dynamic matcher methods" do
      expect(self).to respond_to(:be_happy, :have_eyes_closed)
    end

    it "supports the optional `include_private` arg" do
      expect(respond_to?(:puts, true)).to eq true
      expect(respond_to?(:puts, false)).to eq false
      expect(respond_to?(:puts)).to eq false
    end

    it "allows `method` to get dynamic matcher methods", :if => RUBY_VERSION.to_f >= 1.9 do
      expect(method(:be_happy).call).to be_a(be_happy.class)
    end
  end
end

module RSpec
  module Matchers
    RSpec.describe ".is_a_matcher?" do
      it 'does not match BasicObject', :if => RUBY_VERSION.to_f > 1.8 do
        expect(RSpec::Matchers.is_a_matcher?(BasicObject.new)).to eq(false)
      end

      it 'is registered with RSpec::Support' do
        expect(RSpec::Support.is_a_matcher?(be_even)).to eq(true)
      end

      it 'does not match a multi-element array' do
        # our original implementation regsitered the matcher definition as
        # `&RSpec::Matchers.method(:is_a_matcher?)`, which has a bug
        # on 1.8.7:
        #
        # irb(main):001:0> def foo(x); end
        # => nil
        # irb(main):002:0> method(:foo).call([1, 2, 3])
        # => nil
        # irb(main):003:0> method(:foo).to_proc.call([1, 2, 3])
        # ArgumentError: wrong number of arguments (3 for 1)
        #   from (irb):1:in `foo'
        #   from (irb):1:in `to_proc'
        #   from (irb):3:in `call'
        #
        # This spec guards against a regression for that case.
        expect(RSpec::Support.is_a_matcher?([1, 2, 3])).to eq(false)
      end
    end

    RSpec.describe "built in matchers" do
      let(:matchers) do
        BuiltIn.constants.map { |n| BuiltIn.const_get(n) }.select do |m|
          m.method_defined?(:matches?) && m.method_defined?(:failure_message)
        end
      end

      specify "they all have defined #=== so they can be composable" do
        missing_threequals = matchers.select do |m|
          m.instance_method(:===).owner == ::Kernel
        end

        # This spec is merely to make sure we don't forget to make
        # a built-in matcher implement `===`. It doesn't check the
        # semantics of that. Use the "an RSpec matcher" shared
        # example group to actually check the semantics.
        expect(missing_threequals).to eq([])
      end

      specify "they all have defined #and and #or so they support compound expectations" do
        noncompound_matchers = matchers.reject do |m|
          m.method_defined?(:and) || m.method_defined?(:or)
        end

        expect(noncompound_matchers).to eq([])
      end

      shared_examples "a well-behaved method_missing hook" do
        include MinitestIntegration

        it "raises a NoMethodError (and not SystemStackError) for an undefined method" do
          with_minitest_loaded do
            expect { subject.some_undefined_method }.to raise_error(NoMethodError)
          end
        end
      end

      describe "RSpec::Matchers method_missing hook", :slow do
        subject { self }

        it_behaves_like "a well-behaved method_missing hook"

        context 'when invoked in a Minitest::Test' do
          subject { Minitest::Test.allocate }
          it_behaves_like "a well-behaved method_missing hook"
        end
      end
    end
  end
end
