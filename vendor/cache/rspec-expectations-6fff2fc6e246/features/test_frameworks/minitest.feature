Feature: Minitest integration

  rspec-expectations is a stand-alone gem that can be used without the rest of RSpec. If you
  like minitest as your test runner, but prefer RSpec's approach to expressing expectations,
  you can have both.

  To integrate rspec-expectations with minitest, require `rspec/expectations/minitest_integration`.

  Scenario: use rspec/expectations with minitest
    Given a file named "rspec_expectations_test.rb" with:
      """ruby
      require 'minitest/autorun'
      require 'rspec/expectations/minitest_integration'

      class RSpecExpectationsTest < Minitest::Test
        RSpec::Matchers.define :be_an_integer do
          match { |actual| Integer === actual }
        end

        def be_an_int
          # This is actually an internal rspec-expectations API, but is used
          # here to demonstrate that deprecation warnings from within
          # rspec-expectations work correcty without depending on rspec-core
          RSpec.deprecate(:be_an_int, :replacement => :be_an_integer)
          be_an_integer
        end

        def test_passing_expectation
          expect(1 + 3).to eq 4
        end

        def test_failing_expectation
          expect([1, 2]).to be_empty
        end

        def test_custom_matcher_with_deprecation_warning
          expect(1).to be_an_int
        end

        def test_using_aggregate_failures
          aggregate_failures do
            expect(1).to be_even
            expect(2).to be_odd
          end
        end
      end
      """
     When I run `ruby rspec_expectations_test.rb`
     Then the output should contain "4 runs, 5 assertions, 2 failures, 0 errors"
      And the output should contain "expected `[1, 2].empty?` to be truthy, got false"
      And the output should contain "be_an_int is deprecated"
      And the output should contain "Got 2 failures from failure aggregation block"

  Scenario: use rspec/expectations with minitest/spec
    Given a file named "rspec_expectations_spec.rb" with:
      """ruby
      require 'minitest/autorun'
      require 'minitest/spec'
      require 'rspec/expectations/minitest_integration'

      describe "Using RSpec::Expectations with Minitest::Spec" do
        RSpec::Matchers.define :be_an_integer do
          match { |actual| Integer === actual }
        end

        it 'passes an expectation' do
          expect(1 + 3).to eq 4
        end

        it 'fails an expectation' do
          expect([1, 2]).to be_empty
        end

        it 'passes a block expectation' do
          expect { 1 / 0 }.to raise_error(ZeroDivisionError)
        end

        it 'fails a block expectation' do
          expect { 1 / 1 }.to raise_error(ZeroDivisionError)
        end

        it 'passes a negative expectation (using `not_to`)' do
          expect(1).not_to eq 2
        end

        it 'fails a negative expectation (using `to_not`)' do
          expect(1).to_not eq 1
        end

        it 'fails multiple expectations' do
          aggregate_failures do
            expect(1).to be_even
            expect(2).to be_odd
          end
        end

        it 'passes a minitest expectation' do
          expect(1 + 3).must_equal 4
        end

        it 'fails a minitest expectation' do
          expect([1, 2]).must_be :empty?
        end
      end
      """
     When I run `ruby rspec_expectations_spec.rb`
     Then the output should contain "9 runs, 10 assertions, 5 failures, 0 errors"
      And the output should contain "expected `[1, 2].empty?` to be truthy, got false"
      And the output should contain "expected ZeroDivisionError but nothing was raised"
      And the output should contain "Got 2 failures from failure aggregation block"
      And the output should contain "Expected [1, 2] to be empty?"
