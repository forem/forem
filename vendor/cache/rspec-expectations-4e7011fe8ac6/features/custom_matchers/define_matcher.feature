Feature: Define a custom matcher

  rspec-expectations provides a DSL for defining custom matchers. These are often useful for expressing expectations in the domain of your application.

  Behind the scenes `RSpec::Matchers.define` evaluates the `define` block in the context of a singleton class. If you need to write a more complex matcher and would like to use the `Class`-approach yourself, please head over to our `API`-documentation and read [the docs](http://rspec.info/documentation/latest/rspec-expectations/RSpec/Matchers/MatcherProtocol.html) about the `MatcherProtocol`.

  Scenario: Define a matcher with default messages
    Given a file named "matcher_with_default_message_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :be_a_multiple_of do |expected|
        match do |actual|
          actual % expected == 0
        end
      end

      RSpec.describe 9 do
        it { is_expected.to be_a_multiple_of(3) }
      end

      RSpec.describe 9 do
        it { is_expected.not_to be_a_multiple_of(4) }
      end

      # fail intentionally to generate expected output
      RSpec.describe 9 do
        it { is_expected.to be_a_multiple_of(4) }
      end

      # fail intentionally to generate expected output
      RSpec.describe 9 do
        it { is_expected.not_to be_a_multiple_of(3) }
      end
      """
    When I run `rspec ./matcher_with_default_message_spec.rb --format documentation`
    Then the exit status should not be 0

    And the output should contain "is expected to be a multiple of 3"
    And the output should contain "is expected not to be a multiple of 4"
    And the output should contain "Failure/Error: it { is_expected.to be_a_multiple_of(4) }"
    And the output should contain "Failure/Error: it { is_expected.not_to be_a_multiple_of(3) }"

    And the output should contain "4 examples, 2 failures"
    And the output should contain "expected 9 to be a multiple of 4"
    And the output should contain "expected 9 not to be a multiple of 3"

  Scenario: Overriding the failure_message
    Given a file named "matcher_with_failure_message_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :be_a_multiple_of do |expected|
        match do |actual|
          actual % expected == 0
        end
        failure_message do |actual|
          "expected that #{actual} would be a multiple of #{expected}"
        end
      end

      # fail intentionally to generate expected output
      RSpec.describe 9 do
        it { is_expected.to be_a_multiple_of(4) }
      end
      """
    When I run `rspec ./matcher_with_failure_message_spec.rb`
    Then the exit status should not be 0
    And the stdout should contain "1 example, 1 failure"
    And the stdout should contain "expected that 9 would be a multiple of 4"

  Scenario: Overriding the failure_message_when_negated
    Given a file named "matcher_with_failure_for_message_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :be_a_multiple_of do |expected|
        match do |actual|
          actual % expected == 0
        end
        failure_message_when_negated do |actual|
          "expected that #{actual} would not be a multiple of #{expected}"
        end
      end

      # fail intentionally to generate expected output
      RSpec.describe 9 do
        it { is_expected.not_to be_a_multiple_of(3) }
      end
      """
    When I run `rspec ./matcher_with_failure_for_message_spec.rb`
    Then the exit status should not be 0
    And the stdout should contain "1 example, 1 failure"
    And the stdout should contain "expected that 9 would not be a multiple of 3"

  Scenario: Overriding the description
    Given a file named "matcher_overriding_description_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :be_a_multiple_of do |expected|
        match do |actual|
          actual % expected == 0
        end
        description do
          "be multiple of #{expected}"
        end
      end

      RSpec.describe 9 do
        it { is_expected.to be_a_multiple_of(3) }
      end

      RSpec.describe 9 do
        it { is_expected.not_to be_a_multiple_of(4) }
      end
      """
    When I run `rspec ./matcher_overriding_description_spec.rb --format documentation`
    Then the exit status should be 0
    And the stdout should contain "2 examples, 0 failures"
    And the stdout should contain "is expected to be multiple of 3"
    And the stdout should contain "is expected not to be multiple of 4"

  Scenario: With no args
    Given a file named "matcher_with_no_args_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :have_7_fingers do
        match do |thing|
          thing.fingers.length == 7
        end
      end

      class Thing
        def fingers; (1..7).collect {"finger"}; end
      end

      RSpec.describe Thing do
        it { is_expected.to have_7_fingers }
      end
      """
    When I run `rspec ./matcher_with_no_args_spec.rb --format documentation`
    Then the exit status should be 0
    And the stdout should contain "1 example, 0 failures"
    And the stdout should contain "is expected to have 7 fingers"

  Scenario: With multiple args
    Given a file named "matcher_with_multiple_args_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :be_the_sum_of do |a,b,c,d|
        match do |sum|
          a + b + c + d == sum
        end
      end

      RSpec.describe 10 do
        it { is_expected.to be_the_sum_of(1,2,3,4) }
      end
      """
    When I run `rspec ./matcher_with_multiple_args_spec.rb --format documentation`
    Then the exit status should be 0
    And the stdout should contain "1 example, 0 failures"
    And the stdout should contain "is expected to be the sum of 1, 2, 3, and 4"

  Scenario: With a block arg
    Given a file named "matcher_with_block_arg_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :be_lazily_equal_to do
        match do |obj|
          obj == block_arg.call
        end

        description { "be lazily equal to #{block_arg.call}" }
      end

      RSpec.describe 10 do
        it { is_expected.to be_lazily_equal_to { 10 } }
      end
      """
    When I run `rspec ./matcher_with_block_arg_spec.rb --format documentation`
    Then the exit status should be 0
    And the stdout should contain "1 example, 0 failures"
    And the stdout should contain "is expected to be lazily equal to 10"

  Scenario: With helper methods
    Given a file named "matcher_with_internal_helper_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec::Matchers.define :have_same_elements_as do |sample|
        match do |actual|
          similar?(sample, actual)
        end

        def similar?(a, b)
          a.sort == b.sort
        end
      end

      RSpec.describe "these two arrays" do
        specify "should be similar" do
          expect([1,2,3]).to have_same_elements_as([2,3,1])
        end
      end
      """
    When I run `rspec ./matcher_with_internal_helper_spec.rb`
    Then the exit status should be 0
    And the stdout should contain "1 example, 0 failures"

  Scenario: Scoped in a module
    Given a file named "scoped_matcher_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      module MyHelpers
        extend RSpec::Matchers::DSL

        matcher :be_just_like do |expected|
          match {|actual| actual == expected}
        end
      end

      RSpec.describe "group with MyHelpers" do
        include MyHelpers
        it "has access to the defined matcher" do
          expect(5).to be_just_like(5)
        end
      end

      RSpec.describe "group without MyHelpers" do
        it "does not have access to the defined matcher" do
          expect do
            expect(5).to be_just_like(5)
          end.to raise_exception
        end
      end
      """

    When I run `rspec ./scoped_matcher_spec.rb`
    Then the stdout should contain "2 examples, 0 failures"

  Scenario: Scoped in an example group
    Given a file named "scoped_matcher_spec.rb" with:
      """ruby
      require 'rspec/expectations'

      RSpec.describe "group with matcher" do
        matcher :be_just_like do |expected|
          match {|actual| actual == expected}
        end

        it "has access to the defined matcher" do
          expect(5).to be_just_like(5)
        end

        describe "nested group" do
          it "has access to the defined matcher" do
            expect(5).to be_just_like(5)
          end
        end
      end

      RSpec.describe "group without matcher" do
        it "does not have access to the defined matcher" do
          expect do
            expect(5).to be_just_like(5)
          end.to raise_exception
        end
      end
      """

    When I run `rspec scoped_matcher_spec.rb`
    Then the output should contain "3 examples, 0 failures"

  Scenario: Matcher with separate logic for expect().to and expect().not_to
    Given a file named "matcher_with_separate_should_not_logic_spec.rb" with:
      """ruby
      RSpec::Matchers.define :contain do |*expected|
        match do |actual|
          expected.all? { |e| actual.include?(e) }
        end

        match_when_negated do |actual|
          expected.none? { |e| actual.include?(e) }
        end
      end

      RSpec.describe [1, 2, 3] do
        it { is_expected.to contain(1, 2) }
        it { is_expected.not_to contain(4, 5, 6) }

        # deliberate failures
        it { is_expected.to contain(1, 4) }
        it { is_expected.not_to contain(1, 4) }
      end
      """
    When I run `rspec matcher_with_separate_should_not_logic_spec.rb`
    Then the output should contain all of these:
      | 4 examples, 2 failures                    |
      | expected [1, 2, 3] to contain 1 and 4     |
      | expected [1, 2, 3] not to contain 1 and 4 |

  Scenario: Use define_method to create a helper method with access to matcher params
    Given a file named "define_method_spec.rb" with:
      """ruby
      RSpec::Matchers.define :be_a_multiple_of do |expected|
        define_method :is_multiple? do |actual|
          actual % expected == 0
        end
        match { |actual| is_multiple?(actual) }
      end

      RSpec.describe 9 do
        it { is_expected.to be_a_multiple_of(3) }
        it { is_expected.not_to be_a_multiple_of(4) }

        # deliberate failures
        it { is_expected.to be_a_multiple_of(2) }
        it { is_expected.not_to be_a_multiple_of(3) }
      end
      """
    When I run `rspec define_method_spec.rb`
    Then the output should contain all of these:
      | 4 examples, 2 failures               |
      | expected 9 to be a multiple of 2     |
      | expected 9 not to be a multiple of 3 |

  Scenario: Include a module with helper methods in the matcher
    Given a file named "include_module_spec.rb" with:
      """ruby
      module MatcherHelpers
        def is_multiple?(actual, expected)
          actual % expected == 0
        end
      end

      RSpec::Matchers.define :be_a_multiple_of do |expected|
        include MatcherHelpers
        match { |actual| is_multiple?(actual, expected) }
      end

      RSpec.describe 9 do
        it { is_expected.to be_a_multiple_of(3) }
        it { is_expected.not_to be_a_multiple_of(4) }

        # deliberate failures
        it { is_expected.to be_a_multiple_of(2) }
        it { is_expected.not_to be_a_multiple_of(3) }
      end
      """
    When I run `rspec include_module_spec.rb`
    Then the output should contain all of these:
      | 4 examples, 2 failures               |
      | expected 9 to be a multiple of 2     |
      | expected 9 not to be a multiple of 3 |

  Scenario: Using values_match? to compare values and/or compound matchers.

    Given a file named "compare_values_spec.rb" with:
      """ruby
      RSpec::Matchers.define :have_content do |expected|
        match do |actual|
          # The order of arguments is important for `values_match?`, e.g.
          # especially if your matcher should handle `Regexp`-objects
          # (`/regex/`): First comes the `expected` value, second the `actual`
          # one.
          values_match? expected, actual
        end
      end

      RSpec.describe 'a' do
        it { is_expected.to have_content 'a' }
      end

      RSpec.describe 'a' do
        it { is_expected.to have_content /a/ }
      end

      RSpec.describe 'a' do
        it { is_expected.to have_content a_string_starting_with('a') }
      end
      """
    When I run `rspec ./compare_values_spec.rb --format documentation`
    Then the exit status should be 0

  Scenario: Error handling

    Make sure your matcher returns either `true` or `false`. Take care to handle exceptions appropriately in your matcher, e.g. most cases you might want your matcher to return `false` if an exception - e.g. ArgumentError - occures, but there might be edge cases where you want to pass the exception to the user.

    You should handle each `StandardError` with care! Do not handle them all in one.

    ```ruby
    match do |actual|
      begin
        '[...] Some code'
      rescue ArgumentError
        false
      end
    end
    ```

    Given a file named "error_handling_spec.rb" with:
      """ruby
      class CustomClass; end

      RSpec::Matchers.define :is_lower_than do |expected|
        match do |actual|
          begin
            actual < expected
          rescue ArgumentError
            false
          end
        end
      end

      RSpec.describe 1 do
        it { is_expected.to is_lower_than 2 }
      end

      RSpec.describe 1 do
        it { is_expected.not_to is_lower_than 'a' }
      end

      RSpec.describe CustomClass do
        it { expect { is_expected.not_to is_lower_than 2 }.to raise_error NoMethodError }
      end

      """
    When I run `rspec ./error_handling_spec.rb --format documentation`
    Then the exit status should be 0

  Scenario: Define aliases for your matcher

    If you want your matcher to be readable in different contexts, you can use the `.alias_matcher`-method to provide an alias for your matcher.

    Given a file named "alias_spec.rb" with:
      """ruby
      RSpec::Matchers.define :be_a_multiple_of do |expected|
        match do |actual|
          actual % expected == 0
        end
      end

      RSpec::Matchers.alias_matcher :be_n_of , :be_a_multiple_of

      RSpec.describe 9 do
        it { is_expected.to be_n_of(3) }
      end
      """
    When I run `rspec ./alias_spec.rb --format documentation`
    Then the exit status should be 0
