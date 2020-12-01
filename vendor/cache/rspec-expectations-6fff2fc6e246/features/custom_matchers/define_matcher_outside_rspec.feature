Feature: define matcher outside rspec

  You can define custom matchers when using rspec-expectations outside of rspec-core.

  Scenario: define a matcher with default messages
    Given a file named "test_multiples.rb" with:
      """ruby
      require "minitest/autorun"
      require "rspec/expectations/minitest_integration"

      RSpec::Matchers.define :be_a_multiple_of do |expected|
        match do |actual|
          actual % expected == 0
        end
      end

      class TestMultiples < Minitest::Test

        def test_9_should_be_a_multiple_of_3
          expect(9).to be_a_multiple_of(3)
        end

        def test_9_should_be_a_multiple_of_4
          expect(9).to be_a_multiple_of(4)
        end

      end
      """
    When I run `ruby test_multiples.rb`
    Then the exit status should not be 0
    And the output should contain "expected 9 to be a multiple of 4"
    And the output should contain "2 runs, 2 assertions, 1 failures, 0 errors"
