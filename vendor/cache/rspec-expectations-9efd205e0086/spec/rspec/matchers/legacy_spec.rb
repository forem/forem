module RSpec
  module Matchers
    RSpec.describe "Legacy matchers" do
      it 'still provides a `LegacyMacherAdapter` constant because 3.0 was released with ' \
         'it and it would be a SemVer violation to remove it before 4.0' do
        expect(Expectations::LegacyMacherAdapter).to be(Expectations::LegacyMatcherAdapter)
      end

      shared_examples "a matcher written against a legacy protocol" do |matcher_class|
        matcher = matcher_class.new
        before { allow_deprecation }

        backwards_compat_matcher = Class.new(matcher_class) do
          def failure_message; "failure when positive"; end
          def failure_message_when_negated; "failure when negative"; end
        end.new

        it 'is still considered to be a matcher' do
          expect(Matchers.is_a_matcher?(matcher)).to be true
        end

        context 'when matched positively' do
          it 'returns the positive expectation failure message' do
            expect {
              expect(false).to matcher
            }.to fail_with("failure when positive")
          end

          it 'warns about the deprecated protocol' do
            expect_warn_deprecation(/legacy\s+RSpec\s+matcher.+#{__FILE__}:#{__LINE__ + 1}/m)
            expect(true).to matcher
          end

          it 'does not warn when it also defines the current methods (i.e. to be compatible on multiple RSpec versions)' do
            expect_no_deprecations

            expect {
              expect(false).to backwards_compat_matcher
            }.to fail_with("failure when positive")
          end
        end

        context 'when matched negatively' do
          it 'returns the negative expectation failure message' do
            expect {
              expect(true).not_to matcher
            }.to fail_with("failure when negative")
          end

          it 'warns about the deprecated protocol' do
            expect_warn_deprecation(/legacy\s+RSpec\s+matcher.+#{__FILE__}:#{__LINE__ + 1}/m)
            expect(false).not_to matcher
          end

          it 'does not warn when it also defines the current methods (i.e. to be compatible on multiple RSpec versions)' do
            expect_no_deprecations

            expect {
              expect(true).not_to backwards_compat_matcher
            }.to fail_with("failure when negative")
          end

          def pending_on_rbx
            return unless defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
            pending "intermittently fails on RBX due to https://github.com/rubinius/rubinius/issues/2845"
          end

          it 'calls `does_not_match?` if it is defined on the matcher' do
            pending_on_rbx

            called = false
            with_does_not_match = Class.new(matcher_class) do
              define_method(:does_not_match?) { |actual| called = true; !actual }
            end.new

            expect(false).not_to with_does_not_match
            expect(called).to be true
          end
        end
      end

      context "written using the RSpec 2.x `failure_message_for_should` and `failure_message_for_should_not` protocol" do
        matcher_class = Class.new do
          def matches?(actual); actual; end
          def failure_message_for_should; "failure when positive"; end
          def failure_message_for_should_not; "failure when negative"; end
        end

        it_behaves_like "a matcher written against a legacy protocol", matcher_class
      end

      context "written using the older `failure_message` and `negative_failure_message` protocol" do
        matcher_class = Class.new do
          def matches?(actual); actual; end
          def failure_message; "failure when positive"; end
          def negative_failure_message; "failure when negative"; end
        end

        it_behaves_like "a matcher written against a legacy protocol", matcher_class
      end
    end
  end
end
