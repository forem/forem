RSpec.describe "a matcher defined using the matcher DSL" do
  def question?
    :answer
  end

  def ok
    "ok"
  end

  it "supports calling custom matchers from within other custom matchers" do
    RSpec::Matchers.define :be_ok do
      match { |actual| actual == ok }
    end

    RSpec::Matchers.define :be_well do
      match { |actual| expect(actual).to be_ok }
    end

    expect(ok).to be_well
  end

  it "has access to methods available in the scope of the example" do
    RSpec::Matchers.define(:matcher_a) {}
    expect(matcher_a.question?).to eq(:answer)
  end

  it "raises when method is missing from local scope as well as matcher" do
    RSpec::Matchers.define(:matcher_b) {}
    expect { matcher_b.i_dont_exist }.to raise_error(NameError)
  end

  if RSpec::Support::RubyFeatures.required_kw_args_supported?
    binding.eval(<<-CODE, __FILE__, __LINE__)
    it 'supports the use of required keyword arguments in definition block' do
      RSpec::Matchers.define(:match_required_kw) do |bar:|
        match { expect(actual).to eq bar }
      end
      expect(1).to match_required_kw(bar: 1)
    end

    def kw(a:)
      a
    end

    it "supports the use of required keyword arguments on methods" do
      RSpec::Matchers.define(:matcher_required_kw_on_method) {}
      expect(matcher_required_kw_on_method.kw(a: 1)).to eq(1)
    end
    CODE
  end

  if RSpec::Support::RubyFeatures.kw_args_supported?
    binding.eval(<<-CODE, __FILE__, __LINE__)
    it 'supports the use of optional keyword arguments in definition block' do
      RSpec::Matchers.define(:match_optional_kw) do |bar: nil|
        match { expect(actual).to eq bar }
      end
      expect(1).to match_optional_kw(bar: 1)
    end

    def optional_kw(a: nil)
      a
    end

    it "supports the use of optional keyword arguments on methods" do
      RSpec::Matchers.define(:matcher_optional_kw_on_method) {}
      expect(matcher_optional_kw_on_method.optional_kw(a: 1)).to eq(1)
    end
    CODE
  end

  it "clears user instance variables between invocations" do
    RSpec::Matchers.define(:be_just_like) do |expected|
      match do |actual|
        @foo ||= expected
        @foo == actual
      end
    end

    expect(3).to be_just_like(3)
    expect(4).to be_just_like(4)
  end

  describe '#block_arg' do
    before(:context) do
      RSpec::Matchers.define :be_lazily_equal_to do
        match { actual == block_arg.call }

        description do
          "be lazily equal to #{block_arg.call}"
        end
      end
    end

    it "it is used in a passing condition" do
      expect(1).to be_lazily_equal_to { 1 }
    end

    it "it is used in a failing condition" do
      expect { expect(1).to be_lazily_equal_to { 2 } }.to fail_with(/be lazily equal to 2/)
    end
  end

  it "warns when passing block to the block of define", :if => (RUBY_VERSION.to_f > 1.8) do
    expect(RSpec).to receive(:warning).with(/be_warning.*a_block.*block_arg/)

    RSpec::Matchers.define :be_warning do |&a_block|
      match { a_block }
    end
  end

  describe "#respond_to?" do
    it "returns true for methods in example scope" do
      RSpec::Matchers.define(:matcher_c) {}
      expect(matcher_c).to respond_to(:question?)
    end

    it "returns false for methods not defined in matcher or example scope" do
      RSpec::Matchers.define(:matcher_d) {}
      expect(matcher_d).not_to respond_to(:i_dont_exist)
    end
  end
end

class UnexpectedError < StandardError; end
module MatcherHelperModule
  def self.included(base)
    base.module_exec do
      def included_method; end
    end
  end

  def self.extended(base)
    base.instance_exec do
      def extended_method; end
    end
  end

  def greeting
    "Hello, World"
  end
end

module RSpec::Matchers::DSL
  RSpec.describe "#alias_matcher" do
    describe "an alias matcher defined in the current scope" do
      alias_matcher :be_untrue_in_this_scope, :be_falsy

      it "is available only in the current scope" do
        expect(false).to be_untrue_in_this_scope
      end
    end

    describe "an aliased matcher defined in another scope" do
      it "is not available in the current scope" do
        expect {
          expect(false).to be_untrue_in_this_scope
        }.to fail_with("expected false to respond to `untrue_in_this_scope?`")
      end
    end
  end

  RSpec.describe "#define_negated_matcher" do
    describe "a negated matcher defined in the current scope" do
      define_negated_matcher :be_untrue_in_this_scope, :be_truthy

      it "is available only in the current scope" do
        expect(false).to be_untrue_in_this_scope
      end
    end

    describe "a negated matcher defined in another scope" do
      it "is not available in the current scope" do
        expect {
          expect(false).to be_untrue_in_this_scope
        }.to fail_with("expected false to respond to `untrue_in_this_scope?`")
      end
    end
  end

  RSpec.describe Matcher do
    def new_matcher(name, *expected, &block)
      RSpec::Matchers::DSL::Matcher.new(name, block, self, *expected)
    end

    it_behaves_like "an RSpec matcher", :valid_value => 1, :invalid_value => 2 do
      let(:matcher) do
        new_matcher(:equal_to_1) do
          match { |v| v == 1 }
        end
      end
    end

    it "can be stored aside and used later" do
      # Supports using rspec-expectation matchers as argument matchers in
      # rspec-mocks.
      RSpec::Matchers.define :example_matcher do |expected|
        match do |actual|
          actual == expected
        end
      end

      m1 = example_matcher(1)
      m2 = example_matcher(2)

      expect(m1.matches?(1)).to be_truthy
      expect(m2.matches?(2)).to be_truthy
    end

    context 'using deprecated APIs' do
      before { allow_deprecation }

      describe "failure_message_for_should" do
        let(:matcher) do
          new_matcher(:foo) do
            match { false }
            failure_message_for_should { "failed" }
          end
        end
        line = __LINE__ - 3

        it 'defines the failure message for a positive expectation' do
          expect {
            expect(nil).to matcher
          }.to fail_with("failed")
        end

        it 'prints a deprecation warning' do
          expect_deprecation_with_call_site(__FILE__, line, /failure_message_for_should/)
          matcher
        end
      end

      describe "failure_message_for_should_not" do
        let(:matcher) do
          new_matcher(:foo) do
            match { true }
            failure_message_for_should_not { "failed" }
          end
        end
        line = __LINE__ - 3

        it 'defines the failure message for a negative expectation' do
          expect {
            expect(nil).not_to matcher
          }.to fail_with("failed")
        end

        it 'prints a deprecation warning' do
          expect_deprecation_with_call_site(__FILE__, line, /failure_message_for_should_not/)
          matcher
        end
      end

      describe "match_for_should" do
        let(:matcher) do
          new_matcher(:foo) do
            match_for_should { |arg| arg }
          end
        end
        line = __LINE__ - 3

        it 'defines the positive expectation match logic' do
          expect(true).to matcher
          expect { expect(false).to matcher }.to fail_with(/foo/)
        end

        it 'prints a deprecation warning' do
          expect_deprecation_with_call_site(__FILE__, line, /match_for_should/)
          matcher
        end
      end

      describe "match_for_should_not" do
        let(:matcher) do
          new_matcher(:foo) do
            match_for_should_not { |arg| !arg }
          end
        end
        line = __LINE__ - 3

        it 'defines the positive expectation match logic' do
          expect(false).not_to matcher
          expect { expect(true).not_to matcher }.to fail_with(/foo/)
        end

        it 'prints a deprecation warning' do
          expect_deprecation_with_call_site(__FILE__, line, /match_for_should_not/)
          matcher
        end
      end
    end

    context "with an included module" do
      let(:matcher) do
        new_matcher(:be_a_greeting) do
          include MatcherHelperModule
          match { |actual| actual == greeting }
        end
      end

      it "has access to the module's methods" do
        matcher.matches?("Hello, World")
      end

      it "runs the module's included hook" do
        expect(matcher).to respond_to(:included_method)
      end

      it "does not run the module's extended hook" do
        expect(matcher).not_to respond_to(:extended_method)
      end

      it 'allows multiple modules to be included at once' do
        m = new_matcher(:multiple_modules) do
          include Enumerable
          include Comparable
        end
        expect(m).to be_a(Enumerable)
        expect(m).to be_a(Comparable)
      end
    end

    context "without overrides" do
      let(:matcher) do
        new_matcher(:be_a_multiple_of, 3) do |multiple|
          match do |actual|
            actual % multiple == 0
          end
        end
      end

      it "provides a default description" do
        expect(matcher.description).to eq "be a multiple of 3"
      end

      it "provides a default positive expectation failure message" do
        expect { expect(8).to matcher }.to fail_with 'expected 8 to be a multiple of 3'
      end

      it "provides a default negative expectation failure message" do
        expect { expect(9).to_not matcher }.to fail_with 'expected 9 not to be a multiple of 3'
      end
    end

    context "without overrides with chained matchers" do
      let(:matcher) do
        new_matcher(:be_bigger_than, 5) do |five|
          match do |to_match|
            (to_match > five) && smaller_than_ceiling?(to_match) && divisible_by_divisor?(to_match)
          end

          match_when_negated do |to_match|
            (to_match <= five) || greater_than_ceiling(to_match) && not_divisible_by_divisor?(to_match)
          end

          chain :and_smaller_than do |ceiling|
            @ceiling = ceiling
          end

          chain :and_divisible_by do |divisor|
            @divisor = divisor
          end

        private

          def smaller_than_ceiling?(to_match)
            to_match < @ceiling
          end

          def greater_than_ceiling(to_match)
            to_match >= @ceiling
          end

          def divisible_by_divisor?(to_match)
            @divisor % to_match == 0
          end

          def not_divisible_by_divisor?(to_match)
            @divisor % to_match != 0
          end
        end
      end

      context "when the matchers are chained" do
        include_context "isolate include_chain_clauses_in_custom_matcher_descriptions"

        context "without include_chain_clauses_in_custom_matcher_descriptions configured" do
          before { RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions = false }
          let(:match) { matcher.and_smaller_than(10).and_divisible_by(3) }

          it "provides a default description that does not include any of the chained matchers' descriptions" do
            expect(match.description).to eq 'be bigger than 5'
          end

          it "provides a default positive expectation failure message that does not include any of the chained matchers' descriptions" do
            expect { expect(8).to match }.to fail_with 'expected 8 to be bigger than 5'
          end

          it "provides a default negative expectation failure message that does not include the any of the chained matchers's descriptions" do
            expect { expect(9).to_not match }.to fail_with 'expected 9 not to be bigger than 5'
          end
        end

        context "with include_chain_clauses_in_custom_matcher_descriptions configured to be true" do
          before do
            expect(RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions?).to be true
          end

          it "provides a default description that includes the chained matchers' descriptions in they were used" do
            expect(matcher.and_divisible_by(3).and_smaller_than(29).and_smaller_than(20).and_divisible_by(5).description).to \
              eq 'be bigger than 5 and divisible by 3 and smaller than 29 and smaller than 20 and divisible by 5'
          end

          it "provides a default positive expectation failure message that includes the chained matchers' failures" do
            expect { expect(30).to matcher.and_smaller_than(29).and_divisible_by(3) }.to \
              fail_with 'expected 30 to be bigger than 5 and smaller than 29 and divisible by 3'
          end

          it "provides a default negative expectation failure message that includes the chained matchers' failures" do
            expect { expect(21).to_not matcher.and_smaller_than(29).and_divisible_by(3) }.to \
              fail_with 'expected 21 not to be bigger than 5 and smaller than 29 and divisible by 3'
          end
        end

        it 'only decides if to include the chained clauses at the time description is invoked' do
          matcher.and_divisible_by(3)

          expect {
            RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions = false
          }.to change { matcher.description }.
            from('be bigger than 5 and divisible by 3').
            to('be bigger than 5')
        end
      end
    end

    context "with separate match logic for positive and negative expectations" do
      let(:matcher) do
        new_matcher(:to_be_composed_of, 7, 11) do |a, b|
          match do |actual|
            actual == a * b
          end

          match_when_negated do |actual|
            actual == a + b
          end
        end
      end

      it "invokes the match block for #matches?" do
        expect(matcher.matches?(77)).to be_truthy
        expect(matcher.matches?(18)).to be_falsey
      end

      it "invokes the match_when_negated block for #does_not_match?" do
        expect(matcher.does_not_match?(77)).to be_falsey
        expect(matcher.does_not_match?(18)).to be_truthy
      end

      it "provides a default failure message for negative expectations" do
        matcher.does_not_match?(77)
        expect(matcher.failure_message_when_negated).to eq "expected 77 not to to be composed of 7 and 11"
      end

      it 'can access helper methods from `match_when_negated`' do
        matcher = new_matcher(:be_foo) do
          def foo
            :foo
          end

          match_when_negated do |actual|
            actual != foo
          end
        end

        expect(matcher.does_not_match?(:bar)).to be true
      end
    end

    it "allows helper methods to be defined with #define_method to have access to matcher parameters" do
      matcher = new_matcher(:name, 3, 4) do |a, b|
        define_method(:sum) { a + b }
      end

      expect(matcher.sum).to eq 7
    end

    it "is not diffable by default" do
      matcher = new_matcher(:name) {}
      expect(matcher).not_to be_diffable
    end

    it "is diffable when told to be" do
      matcher = new_matcher(:name) { diffable }
      expect(matcher).to be_diffable
    end

    it 'handles multiline string diffs' do
      actual   = "LINE1\nline2\n"
      expected = "line1\nline2\n"

      matcher = new_matcher(:custom_match, expected) do
        match { |act| act == expected }
        diffable
      end

      diff = nil
      begin
        allow(RSpec::Matchers.configuration).to receive(:color?).and_return(false)
        expect(actual).to matcher
      rescue RSpec::Expectations::ExpectationNotMetError => e
        diff = e.message.sub(/\A.*Diff:/m, "Diff:").gsub(/^\s*/, '')
      end

      if Diff::LCS::VERSION.to_f < 1.4
        expected_diff = "Diff:\n@@ -1,3 +1,3 @@\n-line1\n+LINE1\nline2\n"
      else
        expected_diff = "Diff:\n@@ -1 +1 @@\n-line1\n+LINE1\n"
      end

      expect(diff).to eq expected_diff
    end

    it 'does not confuse the diffability of different matchers' do
      # Necessary to guard against a regression that involved
      # using a class variable to store the diffable state,
      # which had the side effect of causing all custom matchers
      # to share that state
      m1 = new_matcher(:m1) { diffable }
      m2 = new_matcher(:m2) {}
      m3 = new_matcher(:m3) { diffable }

      expect(m1).to be_diffable
      expect(m2).not_to be_diffable
      expect(m3).to be_diffable
    end

    it "provides expected" do
      matcher = new_matcher(:name, "expected string") {}
      expect(matcher.expected).to eq 'expected string'
    end

    it "provides expected when there is more than one argument" do
      matcher = new_matcher(:name, "expected string", "another arg") {}
      expect(matcher.expected).to eq ['expected string', "another arg"]
    end

    it "provides expected_as_array which returns an array regardless of expected" do
      matcher = new_matcher(:name, "expected string") {}
      expect(matcher.expected_as_array).to eq ['expected string']
      matcher = new_matcher(:name, "expected\nstring") {}
      expect(matcher.expected_as_array).to eq ["expected\nstring"]
      matcher = new_matcher(:name, "expected string", "another arg") {}
      expect(matcher.expected_as_array).to eq ['expected string', "another arg"]
    end

    it "provides actual when `match` is used" do
      matcher = new_matcher(:name, 'expected string') do
        match { |actual| }
      end

      matcher.matches?('actual string')

      expect(matcher.actual).to eq 'actual string'
    end

    it "provides actual when the `match` block accepts splat args" do
      matcher = new_matcher(:actual) do
        match { |*actual| actual == [5] }
      end

      expect(matcher.matches?(5)).to be true
      expect(matcher.matches?(4)).to be false
    end

    it 'allows an early `return` to be used from a `match` block' do
      matcher = new_matcher(:with_return, 5) do |expected|
        match { |actual| return true if expected == actual }
      end

      expect(matcher.matches?(5)).to be true
      expect(matcher.matches?(4)).to be_falsey
    end

    it 'provides actual when `match_unless_raises` is used' do
      matcher = new_matcher(:name, 'expected string') do
        match_unless_raises(SyntaxError) { |actual| }
      end

      matcher.matches?('actual string')

      expect(matcher.actual).to eq 'actual string'
    end

    it 'allows an early `return` to be used from a `match_unless_raises` block' do
      matcher = new_matcher(:with_return) do
        match_unless_raises(ArgumentError) do |actual|
          return actual if [true, false].include?(actual)
          raise ArgumentError
        end
      end

      expect(matcher.matches?(true)).to be true
      # It should match even if it returns false, because no error was raised.
      expect(matcher.matches?(false)).to be true
      expect(matcher.matches?(4)).to be_falsey
    end

    it 'provides actual when `match_when_negated` is used' do
      matcher = new_matcher(:name, 'expected string') do
        match_when_negated { |actual| }
      end

      matcher.does_not_match?('actual string')

      expect(matcher.actual).to eq 'actual string'
    end

    it 'allows an early `return` to be used from a `match_when_negated` block' do
      matcher = new_matcher(:with_return, 5) do |expected|
        match_when_negated { |actual| return true if expected != actual }
      end

      expect(matcher.does_not_match?(5)).to be_falsey
      expect(matcher.does_not_match?(4)).to be true
    end

    context "wrapping another expectation in a `match` block" do
      context "with a positive expectation" do
        let(:matcher) do
          new_matcher(:name, "value") do |expected|
            match do |actual|
              expect(actual).to eq expected
            end
          end
        end

        specify "`match?` returns true if the wrapped expectation passes" do
          expect(matcher.matches?('value')).to be_truthy
        end

        specify "`match?` returns false if the wrapped expectation fails" do
          expect(matcher.matches?('other value')).to be_falsey
        end
      end

      context "with a negative expectation" do
        let(:matcher) do
          new_matcher(:name, "purposely_the_same") do |expected|
            match do |actual|
              expect(actual).not_to eq expected
            end
          end
        end

        specify "`match?` returns true if the wrapped expectation passes" do
          expect(matcher.matches?('purposely_different')).to be_truthy
        end

        specify "`match?` returns false if the wrapped expectation fails" do
          expect(matcher.matches?('purposely_the_same')).to be_falsey
        end
      end

      it "can use the `include` matcher from a `match` block" do
        RSpec::Matchers.define(:descend_from) do |mod|
          match do |klass|
            expect(klass.ancestors).to include(mod)
          end
        end

        expect(Integer).to descend_from(Object)
        expect(Integer).not_to descend_from(Array)

        expect {
          expect(Integer).to descend_from(Array)
        }.to fail_with(/expected Integer to descend from Array/)

        expect {
          expect(Integer).not_to descend_from(Object)
        }.to fail_with(/expected Integer not to descend from Object/)
      end

      it "can use the `match` matcher from a `match` block" do
        RSpec::Matchers.define(:be_a_phone_number_string) do
          match do |string|
            expect(string).to match(/\A\d{3}\-\d{3}\-\d{4}\z/)
          end
        end

        expect("206-123-1234").to be_a_phone_number_string
        expect("foo").not_to be_a_phone_number_string

        expect {
          expect("foo").to be_a_phone_number_string
        }.to fail_with(/expected "foo" to be a phone number string/)

        expect {
          expect("206-123-1234").not_to be_a_phone_number_string
        }.to fail_with(/expected "206-123-1234" not to be a phone number string/)
      end

      context "when used within an `aggregate_failures` block" do
        it 'does not aggregate the inner expectation failure' do
          use_an_internal_expectation = new_matcher(:use_an_internal_expectation) do
            match do |actual|
              expect(actual).to end_with "z"
            end
          end

          expect {
            aggregate_failures do
              expect(1).to be_even
              expect("foo").to use_an_internal_expectation
            end
          }.to fail do |error|
            expect(error).to have_attributes(:failures => [
              an_object_having_attributes(:message => "expected `1.even?` to return true, got false"),
              an_object_having_attributes(:message => 'expected "foo" to use an internal expectation')
            ])
          end
        end

        it 'does not aggregate the inner expectation failure (negation)' do
          use_an_internal_expectation = new_matcher(:use_an_internal_expectation) do
            match_when_negated do |actual|
              expect(actual).not_to end_with "o"
            end
          end

          expect {
            aggregate_failures do
              expect(1).to be_even
              expect("foo").not_to use_an_internal_expectation
            end
          }.to fail do |error|
            expect(error).to have_attributes(:failures => [
              an_object_having_attributes(:message => "expected `1.even?` to return true, got false"),
              an_object_having_attributes(:message => 'expected "foo" not to use an internal expectation')
            ])
          end
        end

        it 'still raises the expectation failure internally in case the matcher relies upon rescuing the error' do
          error_rescued = false

          rescue_failure = new_matcher(:rescue_failure) do
            match do |actual|
              begin
                expect(actual).to eq(2)
              rescue RSpec::Expectations::ExpectationNotMetError
                error_rescued = true
              end
            end
          end

          begin
            aggregate_failures do
              expect(1).to rescue_failure
            end
          rescue RSpec::Expectations::ExpectationNotMetError # rubocop:disable Lint/HandleExceptions
          end

          expect(error_rescued).to be true
        end
      end
    end

    context "wrapping another expectation in a `match_when_negated` block" do
      context "with a positive expectation" do
        let(:matcher) do
          new_matcher(:name, "purposely_the_same") do |expected|
            match_when_negated do |actual|
              expect(actual).to eq expected
            end
          end
        end

        specify "`does_not_match?` returns true if the wrapped expectation passes" do
          expect(matcher.does_not_match?('purposely_the_same')).to be_truthy
        end

        specify "`does_not_match?` returns false if the wrapped expectation fails" do
          expect(matcher.does_not_match?('purposely_different')).to be_falsey
        end
      end

      context "with a negative expectation" do
        let(:matcher) do
          new_matcher(:name, "value") do |expected|
            match_when_negated do |actual|
              expect(actual).not_to eq expected
            end
          end
        end

        specify "`does_not_match?` returns true if the wrapped expectation passes" do
          expect(matcher.does_not_match?('other value')).to be_truthy
        end

        specify "`does_not_match?` returns false if the wrapped expectation fails" do
          expect(matcher.does_not_match?('value')).to be_falsey
        end
      end
    end

    context "with overrides" do
      let(:matcher) do
        new_matcher(:be_boolean, true) do |boolean|
          match do |actual|
            actual
          end
          description do |actual|
            "be the boolean #{boolean} (actual was #{actual})"
          end
          failure_message do |actual|
            "expected #{actual} to be the boolean #{boolean}"
          end
          failure_message_when_negated do |actual|
            "expected #{actual} not to be the boolean #{boolean}"
          end
        end
      end

      it "does not hide result of match block when true" do
        expect(matcher.matches?(true)).to be_truthy
      end

      it "does not hide result of match block when false" do
        expect(matcher.matches?(false)).to be_falsey
      end

      it "overrides the description (which yields `actual`)" do
        matcher.matches?(true)
        expect(matcher.description).to eq "be the boolean true (actual was true)"
      end

      it "overrides the failure message for positive expectations" do
        matcher.matches?(false)
        expect(matcher.failure_message).to eq "expected false to be the boolean true"
      end

      it "overrides the failure message for negative expectations" do
        matcher.matches?(true)
        expect(matcher.failure_message_when_negated).to eq "expected true not to be the boolean true"
      end

      it 'can access helper methods from `description`' do
        matcher = new_matcher(:desc) do
          def subdesc() "sub description" end
          description { "Desc (#{subdesc})" }
        end

        expect(matcher.description).to eq("Desc (sub description)")
      end

      it 'can access helper methods from `failure_message`' do
        matcher = new_matcher(:positive_failure_message) do
          def helper() "helper" end
          failure_message { helper }
        end

        expect(matcher.failure_message).to eq("helper")
      end

      it 'can access helper methods from `failure_message_when_negated`' do
        matcher = new_matcher(:negative_failure_message) do
          def helper() "helper" end
          failure_message_when_negated { helper }
        end

        expect(matcher.failure_message_when_negated).to eq("helper")
      end

      it 'can exit early with a `return` from `description` just like in a method' do
        matcher = new_matcher(:desc) do
          description { return "Desc" }
        end

        expect(matcher.description).to eq("Desc")
      end

      it 'can exit early with a `return` from `failure_message` just like in a method' do
        matcher = new_matcher(:positive_failure_message) do
          failure_message { return "msg" }
        end

        expect(matcher.failure_message).to eq("msg")
      end

      it 'can exit early with a `return` from `failure_message_when_negated` just like in a method' do
        matcher = new_matcher(:negative_failure_message) do
          failure_message_when_negated { return "msg" }
        end

        expect(matcher.failure_message_when_negated).to eq("msg")
      end
    end

    context "with description override and chained matcher" do
      context "by default" do
        let(:matcher) do
          new_matcher(:be_even) do
            match do |to_match|
              to_match.even? && (to_match % @divisible_by == 0)
            end

            chain :and_divisible_by do |divisible_by|
              @divisible_by = divisible_by
            end

            description { super() + " and divisible by #{@divisible_by}" }
          end
        end

        context "with include_chain_clauses_in_custom_matcher_descriptions configured to false" do
          include_context "isolate include_chain_clauses_in_custom_matcher_descriptions"
          before { RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions = false }

          it "provides a default description that does not include any of the chained matchers' descriptions" do
            expect(matcher.and_divisible_by(10).description).to eq 'be even and divisible by 10'
          end
        end

        context "with include_chain_clauses_in_custom_matcher_descriptions configured to true" do
          it "provides a default description that does includes the chained matchers' descriptions" do
            expect(matcher.and_divisible_by(10).description).to eq 'be even and divisible by 10 and divisible by 10'
          end
        end
      end
    end

    context "matching blocks" do
      it 'cannot match blocks by default' do
        matcher = new_matcher(:foo) { match { true } }
        expect(3).to matcher

        expect {
          expect { 3 }.to matcher
        }.to fail_with(/must pass an argument/)
      end

      it 'can match blocks if it declares `supports_block_expectations`' do
        matcher = new_matcher(:foo) do
          match { true }
          supports_block_expectations
        end

        expect(3).to matcher
        expect { 3 }.to matcher
      end

      it 'will not swallow expectation errors from blocks when told to' do
        matcher = new_matcher(:foo) do
          match(:notify_expectation_failures => true) do |actual|
            actual.call
            true
          end
          supports_block_expectations
        end

        expect {
          expect { raise RSpec::Expectations::ExpectationNotMetError.new('original') }.to matcher
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /original/)
      end
    end

    context "matching blocks when negated" do
      it 'cannot match blocks by default' do
        matcher = new_matcher(:foo) { match_when_negated { true } }
        expect(3).to_not matcher

        expect {
          expect { 3 }.to_not matcher
        }.to fail_with(/must pass an argument/)
      end

      it 'can match blocks if it declares `supports_block_expectations`' do
        matcher = new_matcher(:foo) do
          match_when_negated { true }
          supports_block_expectations
        end

        expect(3).to_not matcher
        expect { 3 }.to_not matcher
      end

      it 'will not swallow expectation errors from blocks when told to' do
        matcher = new_matcher(:foo) do
          match_when_negated(:notify_expectation_failures => true) do |actual|
            actual.call
            true
          end
          supports_block_expectations
        end

        expect {
          expect { raise RSpec::Expectations::ExpectationNotMetError.new('original') }.to_not matcher
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /original/)
      end
    end

    context "#new" do
      it "passes matches? arg to match block" do
        matcher = new_matcher(:ignore) do
          match do |actual|
            actual == 5
          end
        end
        expect(matcher.matches?(5)).to be_truthy
      end

      it "exposes arg submitted through #new to matcher block" do
        matcher = new_matcher(:ignore, 4) do |expected|
          match do |actual|
            actual > expected
          end
        end
        expect(matcher.matches?(5)).to be_truthy
      end
    end

    context "with no args" do
      let(:matcher) do
        new_matcher(:matcher_name) do
          match do |actual|
            actual == 5
          end
        end
      end

      it "matches" do
        expect(matcher.matches?(5)).to be_truthy
      end

      it "describes" do
        expect(matcher.description).to eq "matcher name"
      end
    end

    context "with 1 arg" do
      let(:matcher) do
        new_matcher(:matcher_name, 1) do |expected|
          match do |actual|
            actual == 5 && expected == 1
          end
        end
      end

      it "matches" do
        expect(matcher.matches?(5)).to be_truthy
      end

      it "describes" do
        expect(matcher.description).to eq "matcher name 1"
      end
    end

    context "with multiple args" do
      let(:matcher) do
        new_matcher(:matcher_name, 1, 2, 3, 4) do |a, b, c, d|
          match do |sum|
            a + b + c + d == sum
          end
        end
      end

      it "matches" do
        expect(matcher.matches?(10)).to be_truthy
      end

      it "describes" do
        expect(matcher.description).to eq "matcher name 1, 2, 3, and 4"
      end
    end

    it "supports helper methods" do
      matcher = new_matcher(:be_similar_to, [1, 2, 3]) do |sample|
        match do |actual|
          similar?(sample, actual)
        end

        def similar?(a, b)
          a.sort == b.sort
        end
      end

      expect(matcher.matches?([2, 3, 1])).to be_truthy
    end

    it "supports fluent interface" do
      matcher = new_matcher(:first_word) do
        def second_word
          self
        end
      end

      expect(matcher.second_word).to eq matcher
    end

    it "treats method missing normally for undeclared methods" do
      matcher = new_matcher(:ignore) {}
      expect { matcher.non_existent_method }.to raise_error(NoMethodError)
    end

    it "has access to other matchers" do
      matcher = new_matcher(:ignore, 3) do |expected|
        match do |actual|
          extend RSpec::Matchers
          expect(actual).to eql(5 + expected)
        end
      end

      expect(matcher.matches?(8)).to be_truthy
    end

    context 'when multiple instances of the same matcher are used in the same example' do
      RSpec::Matchers.define(:be_like_a) do |expected|
        match { |actual| actual == expected }
        description { "be like a #{expected}" }
        failure_message { "expected to be like a #{expected}" }
        failure_message_when_negated { "expected not to be like a #{expected}" }
      end

      # Note: these bugs were only exposed when creating both instances
      # first, then checking their descriptions/failure messages.
      #
      # That's why we eager-instantiate them here.
      let!(:moose) { be_like_a("moose") }
      let!(:horse) { be_like_a("horse") }

      it 'allows them to use the expected value in the description' do
        expect(horse.description).to eq("be like a horse")
        expect(moose.description).to eq("be like a moose")
      end

      it 'allows them to use the expected value in the positive failure message' do
        expect(moose.failure_message).to eq("expected to be like a moose")
        expect(horse.failure_message).to eq("expected to be like a horse")
      end

      it 'allows them to use the expected value in the negative failure message' do
        expect(moose.failure_message_when_negated).to eq("expected not to be like a moose")
        expect(horse.failure_message_when_negated).to eq("expected not to be like a horse")
      end

      it 'allows them to match separately' do
        expect("moose").to moose
        expect("horse").to horse
        expect("horse").not_to moose
        expect("moose").not_to horse
      end
    end

    describe "#match_unless_raises" do
      context "with an assertion" do
        mod = Module.new do
          def assert_equal(a, b)
            raise UnexpectedError.new("#{b} does not equal #{a}") unless a == b
          end
        end

        let(:matcher) do
          new_matcher(:equal, 4) do |expected|
            include mod
            match_unless_raises UnexpectedError do
              assert_equal expected, actual
            end
          end
        end

        context "with passing assertion" do
          it "passes" do
            expect(matcher.matches?(4)).to be_truthy
          end
        end

        context "with failing assertion" do
          it "fails" do
            expect(matcher.matches?(5)).to be_falsey
          end

          it "provides the raised exception" do
            matcher.matches?(5)
            expect(matcher.rescued_exception.message).to eq("5 does not equal 4")
          end
        end
      end

      context "with an unexpected error" do
        it "raises the error" do
          matcher = new_matcher(:foo, :bar) do |_expected|
            match_unless_raises SyntaxError do |_actual|
              raise "unexpected exception"
            end
          end

          expect {
            matcher.matches?(:bar)
          }.to raise_error("unexpected exception")
        end
      end

      context "without a specified error class" do
        let(:matcher) do
          new_matcher(:foo) do
            match_unless_raises do |actual|
              raise Exception unless actual == 5
            end
          end
        end

        it 'passes if no error is raised' do
          expect(matcher.matches?(5)).to be true
        end

        it 'fails if an exception is raised' do
          expect(matcher.matches?(4)).to be false
        end
      end

    end

    it "can define chainable methods" do
      matcher = new_matcher(:name) do
        chain(:expecting) do |expected_value|
          @expected_value = expected_value
        end
        match { |actual| actual == @expected_value }
      end

      expect(matcher.expecting('value').matches?('value')).to be_truthy
      expect(matcher.expecting('value').matches?('other value')).to be_falsey
    end

    it "can define chainable setters" do
      matcher = new_matcher(:name) do
        chain(:expecting, :expected_value)
        match { |actual| actual == expected_value }
      end

      expect(matcher.expecting('value').matches?('value')).to be_truthy
      expect(matcher.expecting('value').matches?('other value')).to be_falsey
    end

    it "can define chainable setters for several attributes" do
      matcher = new_matcher(:name) do
        chain(:expecting, :expected_value, :min_value, :max_value)
        match { |actual| actual == expected_value && actual >= min_value && actual <= max_value }
      end

      expect(matcher.expecting('value', 'apple', 'zebra').matches?('value')).to be_truthy
      expect(matcher.expecting('value', 'apple', 'zebra').matches?('other value')).to be_falsey
      expect(matcher.expecting('other value', 'parrot', 'zebra').matches?('other value')).to be_falsey
    end

    it "raises when neither a `chain` block nor attribute name is provided" do
      expect do
        new_matcher(:name) do
          chain(:expecting)
        end
      end.to raise_error(ArgumentError)
    end

    it "raises when both a `chain` block and attribute name are provided" do
      expect do
        new_matcher(:name) do
          chain(:expecting, :expected_value) do |expected_value|
            @expected_value = expected_value
          end
        end
      end.to raise_error(ArgumentError)
    end

    it 'can use an early return from a `chain` block' do
      matcher = new_matcher(:name) do
        chain(:expecting) do |expected_value|
          @expected_value = expected_value
          return
        end
        match { |actual| actual == @expected_value }
      end

      expect(matcher.expecting('value').matches?('value')).to be_truthy
      expect(matcher.expecting('value').matches?('other value')).to be_falsey
    end

    it 'allows chainable methods to accept blocks' do
      matcher = new_matcher(:name) do
        chain(:for_block) { |&b| @block = b }
        match { |value| @block.call == value }
      end

      expect(matcher.for_block { 5 }.matches?(5)).to be true
      expect(matcher.for_block { 3 }.matches?(4)).to be false
    end

    it "prevents name collisions on chainable methods from different matchers" do
      m1 = new_matcher(:m1) { chain(:foo) { raise "foo in m1" } }
      m2 = new_matcher(:m2) { chain(:foo) { raise "foo in m2" } }

      expect { m1.foo }.to raise_error("foo in m1")
      expect { m2.foo }.to raise_error("foo in m2")
    end

    context "defined using the dsl" do
      def a_method_in_the_example
        "method defined in the example"
      end

      it "can access methods in the running example" do |example|
        RSpec::Matchers.define(:__access_running_example) do
          match do |_actual|
            a_method_in_the_example == "method defined in the example"
          end
        end
        expect(example).to __access_running_example
      end

      it 'can get a method object for methods in the running example', :if => (RUBY_VERSION.to_f > 1.8) do
        matcher = new_matcher(:get_method_object) {}
        method  = matcher.method(:a_method_in_the_example)
        expect(method.call).to eq("method defined in the example")
      end

      it 'indicates that it responds to a method from the running example' do
        matcher = new_matcher(:respond_to) {}
        expect(matcher).to respond_to(:a_method_in_the_example)
        expect(matcher).not_to respond_to(:a_method_not_in_the_example)
      end

      it "raises NoMethodError for methods not in the running_example" do |example|
        RSpec::Matchers.define(:__raise_no_method_error) do
          match do |_actual|
            self.a_method_not_in_the_example == "method defined in the example" # rubocop:disable Style/RedundantSelf RuboCop bug, should disappear on version update
          end
        end

        expected_msg = "RSpec::Matchers::DSL::Matcher"
        expected_msg = "#{expected_msg} __raise_no_method_error" unless rbx?

        expect {
          expect(example).to __raise_no_method_error
        }.to raise_error(NoMethodError, /#{expected_msg}/)
      end

      def rbx?
        defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
      end
    end

  end
end
