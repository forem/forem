module RSpec::Matchers::BuiltIn
  RSpec.describe BaseMatcher do
    describe "#match_unless_raises" do
      let(:matcher) do
        Class.new(BaseMatcher).new
      end

      it "returns true if there are no errors" do
        expect(matcher.match_unless_raises {}).to be_truthy
      end

      it "returns false if there is an error" do
        expect(matcher.match_unless_raises { raise }).to be_falsey
      end

      it "returns false if the only submitted error is raised" do
        expect(matcher.match_unless_raises(RuntimeError) { raise "foo" }).to be_falsey
      end

      it "returns false if any of several errors submitted is raised" do
        expect(matcher.match_unless_raises(RuntimeError, ArgumentError, NameError) { raise "foo" }).to be_falsey
        expect(matcher.match_unless_raises(RuntimeError, ArgumentError, NameError) { raise ArgumentError.new('') }).to be_falsey
        expect(matcher.match_unless_raises(RuntimeError, ArgumentError, NameError) { raise NameError.new('') }).to be_falsey
      end

      it "re-raises any error other than one of those specified" do
        expect do
          matcher.match_unless_raises(ArgumentError) { raise "foo" }
        end.to raise_error "foo"
      end

      it "stores the rescued exception for use in messages" do
        matcher.match_unless_raises(RuntimeError) { raise "foo" }
        expect(matcher.rescued_exception).to be_a(RuntimeError)
        expect(matcher.rescued_exception.message).to eq("foo")
      end

    end

    describe "#failure_message" do
      context "when the parameter to .new is omitted" do
        it "describes what was expected" do
          matcher_class = Class.new(BaseMatcher) do
            def match(_expected, _actual)
              false
            end
          end

          stub_const("Foo::Bar::BeSomething", matcher_class)

          matcher = matcher_class.new
          matcher.matches?("foo")
          expect(matcher.failure_message).to eq('expected "foo" to be something')
        end
      end
    end

    describe "#===" do
      it "responds the same way as matches?" do
        matcher = Class.new(BaseMatcher) do
          def initialize(expected)
            @expected = expected
          end

          def matches?(actual)
            (@actual = actual) == @expected
          end
        end

        expect(matcher.new(3).matches?(3)).to be_truthy
        expect(matcher.new(3)).to be === 3

        expect(matcher.new(3).matches?(4)).to be_falsey
        expect(matcher.new(3)).not_to be === 4
      end
    end

    describe "default failure message detection" do
      def has_default_failure_messages?(matcher)
        BaseMatcher::DefaultFailureMessages.has_default_failure_messages?(matcher)
      end

      shared_examples_for "detecting default failure message" do
        context "that has no failure message overrides" do
          it "indicates that it has default failure messages" do
            matcher = build_matcher
            expect(has_default_failure_messages?(matcher)).to be true
          end
        end

        context "that overrides `failure_message`" do
          it "indicates that it lacks default failure messages" do
            matcher = build_matcher { def failure_message; end }
            expect(has_default_failure_messages?(matcher)).to be false
          end
        end

        context "that overrides `failure_message_when_negated`" do
          it "indicates that it lacks default failure messages" do
            matcher = build_matcher { def failure_message_when_negated; end }
            expect(has_default_failure_messages?(matcher)).to be false
          end
        end
      end

      context "for a DSL-defined custom macher" do
        include_examples "detecting default failure message" do
          def build_matcher(&block)
            definition = Proc.new do
              match {}
              module_exec(&block) if block
            end

            RSpec::Matchers::DSL::Matcher.new(:matcher_name, definition, self)
          end
        end
      end

      context "for a matcher that subclasses `BaseMatcher`" do
        include_examples "detecting default failure message" do
          def build_matcher(&block)
            Class.new(RSpec::Matchers::BuiltIn::BaseMatcher, &block).new
          end
        end
      end

      context "for a custom matcher that lacks `failure_message_when_negated` (documented as an optional part of the matcher protocol" do
        it "indicates that it lacks default failure messages" do
          matcher = Class.new(RSpec::Matchers::BuiltIn::BaseMatcher) { undef failure_message_when_negated }.new

          expect(RSpec::Support.is_a_matcher?(matcher)).to be true
          expect(has_default_failure_messages?(matcher)).to be false
        end
      end
    end
  end
end
