module ExampleExpectations
  class ArbitraryMatcher
    def initialize(*args, &block)
      if args.last.is_a? Hash
        @expected = args.last[:expected]
      end
      @expected = yield if block
      @block = block
    end

    def matches?(target)
      @target = target
      return @expected == target
    end

    def with(new_value)
      @expected = new_value
      self
    end

    def failure_message
      "expected #{@expected}, got #{@target}"
    end

    def failure_message_when_negated
      "expected not #{@expected}, got #{@target}"
    end
  end

  class PositiveOnlyMatcher < ArbitraryMatcher
    undef failure_message_when_negated rescue nil
  end

  def arbitrary_matcher(*args, &block)
    ArbitraryMatcher.new(*args, &block)
  end

  def positive_only_matcher(*args, &block)
    PositiveOnlyMatcher.new(*args, &block)
  end
end

module RSpec
  module Expectations
    RSpec.describe PositiveExpectationHandler do
      include ExampleExpectations

      it "handles submitted args" do
        expect(5).to arbitrary_matcher(:expected => 5)
        expect(5).to arbitrary_matcher(:expected => "wrong").with(5)
        expect { expect(5).to arbitrary_matcher(:expected => 4) }.to fail_with("expected 4, got 5")
        expect { expect(5).to arbitrary_matcher(:expected => 5).with(4) }.to fail_with("expected 4, got 5")
        expect(5).not_to arbitrary_matcher(:expected => 4)
        expect(5).not_to arbitrary_matcher(:expected => 5).with(4)
        expect { expect(5).not_to arbitrary_matcher(:expected => 5) }.to fail_with("expected not 5, got 5")
        expect { expect(5).not_to arbitrary_matcher(:expected => 4).with(5) }.to fail_with("expected not 5, got 5")
      end

      it "handles the submitted block" do
        expect(5).to arbitrary_matcher { 5 }
        expect(5).to arbitrary_matcher(:expected => 4) { 5 }
        expect(5).to arbitrary_matcher(:expected => 4).with(5) { 3 }
      end

      describe "#handle_matcher" do
        it "asks the matcher if it matches" do
          matcher = double("matcher")
          actual = Object.new
          expect(matcher).to receive(:matches?).with(actual).and_return(true)
          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)
        end

        it "returns the match value" do
          matcher = double("matcher")
          actual = Object.new
          expect(matcher).to receive(:matches?).with(actual).and_return(:this_value)
          expect(RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)).to eq :this_value
        end

        it "calls failure_message if the matcher implements it" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)
        end

        it "calls fail if matcher.diffable?" do
          matcher = double("matcher",
            :diffable? => true,
            :failure_message => "message",
            :matches? => false,
            :expected => 1,
            :actual   => 2
          )
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message", 1, 2)

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)
        end

        it "calls failure_message if the matcher does not implement failure_message" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher)

        end

        it "uses the custom failure message when one is provided" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher, "custom")
        end

        it "uses the custom failure message when one is provided as a callable object" do
          matcher = double("matcher", :failure_message => "message", :matches? => false)
          actual = Object.new

          failure_message = double("failure message", :call => "custom")

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher, failure_message)
        end

        it "add custom failure message to mock matcher if there is one" do
          error_generator = instance_double("RSpec::Mocks::ErrorGenerator", :opts => { :message => {} })
          verifying_message_expectation = instance_double(
            "RSpec::Mocks::VerifyingMessageExpectation",
            :error_generator => error_generator
          )
          matcher = double("matcher", :failure_message => "message", :matches? => verifying_message_expectation)

          actual = Object.new

          handle_matcher_result = RSpec::Expectations::PositiveExpectationHandler.handle_matcher(actual, matcher, "custom")

          expect(handle_matcher_result.error_generator.opts).to eq({ :message => "custom" })
        end
      end
    end

    RSpec.describe NegativeExpectationHandler do
      describe "#handle_matcher" do
        context "when the matcher responds to `does_not_match?`" do
          it "returns true when `does_not_match?` returns true" do
            matcher = double("matcher")
            actual = Object.new

            expect(matcher).to receive(:does_not_match?).with(actual).and_return(true)
            expect(RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)).to be_truthy
          end

          it "raises an expectation failure when `does_not_match?` returns false" do
            matcher = double("matcher", :failure_message_when_negated => "Error!")
            actual = Object.new

            expect(matcher).to receive(:does_not_match?).with(actual).and_return(false)
            expect {
              RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "Error!")
          end
        end

        context "when the matcher does not respond to `does_not_match?`" do
          it "returns true when `matches?` returns false" do
            matcher = double("matcher")
            actual = Object.new

            expect(matcher).to receive(:matches?).with(actual).and_return(false)
            expect(RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)).to be_truthy
          end

          it "raises an expectation failure when `matches?` returns true" do
            matcher = double("matcher", :failure_message_when_negated => "Error!")
            actual = Object.new

            expect(matcher).to receive(:matches?).with(actual).and_return(true)
            expect {
              RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError, "Error!")
          end
        end

        it "calls fail if matcher.diffable?" do
          matcher = double("matcher",
            :diffable? => true,
            :failure_message_when_negated => "message",
            :matches? => true,
            :expected => 1,
            :actual   => 2
          )
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("message", 1, 2)

          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher)
        end

        it "uses the custom failure message when one is provided" do
          matcher = double("matcher", :failure_message_when_negated => "message", :matches? => true)
          actual = Object.new

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher, "custom")
        end

        it "uses the custom failure message when one is provided as a callable object" do
          matcher = double("matcher", :failure_message_when_negated => "message", :matches? => true)
          actual = Object.new

          failure_message = double("failure message", :call => "custom")

          expect(::RSpec::Expectations).to receive(:fail_with).with("custom")

          RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher, failure_message)
        end

        it "add custom failure message to mock matcher if there is one" do
          error_generator = instance_double("RSpec::Mocks::ErrorGenerator", :opts => { :message => {} })
          verifying_message_expectation = instance_double(
            "RSpec::Mocks::VerifyingMessageExpectation",
            :error_generator => error_generator
          )
          matcher = double(
            "matcher",
            :failure_message_when_negated => "custom",
            :does_not_match? => verifying_message_expectation
          )

          actual = Object.new

          handle_matcher_result = RSpec::Expectations::NegativeExpectationHandler.handle_matcher(actual, matcher, "custom")

          expect(handle_matcher_result.error_generator.opts).to eq({ :message => "custom" })
        end
      end
    end
  end
end
