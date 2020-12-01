Feature: Predicate matchers

  Ruby objects commonly provide predicate methods:

    ```ruby
    7.zero?                  # => false
    0.zero?                  # => true
    [1].empty?               # => false
    [].empty?                # => true
    { :a => 5 }.has_key?(:b) # => false
    { :b => 5 }.has_key?(:b) # => true
    ```

  You could use a basic equality matcher to set expectations on these:

    ```ruby
    expect(7.zero?).to eq true # fails with "expected true, got false (using ==)"
    ```

  ...but RSpec provides dynamic predicate matchers that are more readable and provide
  better failure output.

  For any predicate method, RSpec gives you a corresponding matcher. Simply prefix the
  method with `be_` and remove the question mark. Examples:

    ```ruby
    expect(7).not_to be_zero       # calls 7.zero?
    expect([]).to be_empty         # calls [].empty?
    expect(x).to be_multiple_of(3) # calls x.multiple_of?(3)
    ```

  Alternately, for a predicate method that begins with `has_` like `Hash#has_key?`, RSpec allows
  you to use an alternate form since `be_has_key` makes no sense.

    ```ruby
    expect(hash).to have_key(:foo)       # calls hash.has_key?(:foo)
    expect(array).not_to have_odd_values # calls array.has_odd_values?
    ```

  In either case, RSpec provides nice, clear error messages, such as:

    `expected zero? to be truthy, got false`

  Calling private methods will also fail:

    `expected private_method? to return true but it's a private method`

  Any arguments passed to the matcher will be passed on to the predicate method.

  Scenario: should be_zero (based on Integer#zero?)
    Given a file named "should_be_zero_spec.rb" with:
      """ruby
      RSpec.describe 0 do
        it { is_expected.to be_zero }
      end

      RSpec.describe 7 do
        it { is_expected.to be_zero } # deliberate failure
      end
      """
    When I run `rspec should_be_zero_spec.rb`
    Then the output should contain "2 examples, 1 failure"
     And the output should contain "expected `7.zero?` to be truthy, got false"

  Scenario: should_not be_empty (based on Array#empty?)
    Given a file named "should_not_be_empty_spec.rb" with:
      """ruby
      RSpec.describe [1, 2, 3] do
        it { is_expected.not_to be_empty }
      end

      RSpec.describe [] do
        it { is_expected.not_to be_empty } # deliberate failure
      end
      """
    When I run `rspec should_not_be_empty_spec.rb`
    Then the output should contain "2 examples, 1 failure"
     And the output should contain "expected `[].empty?` to be falsey, got true"

   Scenario: should have_key (based on Hash#has_key?)
    Given a file named "should_have_key_spec.rb" with:
      """ruby
      RSpec.describe Hash do
        subject { { :foo => 7 } }
        it { is_expected.to have_key(:foo) }
        it { is_expected.to have_key(:bar) } # deliberate failure
      end
      """
    When I run `rspec should_have_key_spec.rb`
    Then the output should contain "2 examples, 1 failure"
     And the output should contain "expected `{:foo=>7}.has_key?(:bar)` to be truthy, got false"

   Scenario: should_not have_all_string_keys (based on custom #has_all_string_keys? method)
     Given a file named "should_not_have_all_string_keys_spec.rb" with:
       """ruby
       class Float
         def has_decimals?
           round != self
         end
       end

       RSpec.describe Float do
         context 'with decimals' do
           subject { 4.2 }

           it { is_expected.to have_decimals }
         end

         context 'with no decimals' do
           subject { 42.0 }
           it { is_expected.to have_decimals } # deliberate failure
         end
       end
       """
     When I run `rspec should_not_have_all_string_keys_spec.rb`
     Then the output should contain "2 examples, 1 failure"
      And the output should contain "expected `42.0.has_decimals?` to be truthy, got false"

   Scenario: matcher arguments are passed on to the predicate method
     Given a file named "predicate_matcher_argument_spec.rb" with:
       """ruby
       class Integer
         def multiple_of?(x)
           (self % x).zero?
         end
       end

       RSpec.describe 12 do
         it { is_expected.to be_multiple_of(3) }
         it { is_expected.not_to be_multiple_of(7) }

         # deliberate failures
         it { is_expected.not_to be_multiple_of(4) }
         it { is_expected.to be_multiple_of(5) }
       end
       """
     When I run `rspec predicate_matcher_argument_spec.rb`
     Then the output should contain "4 examples, 2 failures"
      And the output should contain "expected `12.multiple_of?(4)` to be falsey, got true"
      And the output should contain "expected `12.multiple_of?(5)` to be truthy, got false"

    Scenario: the config `strict_predicate_matchers` impacts matching of results other than `true` and `false`
      Given a file named "strict_or_not.rb" with:
        """ruby
        class StrangeResult
          def has_strange_result?
            42
          end
        end

        RSpec.describe StrangeResult do
          subject { StrangeResult.new }

          before do
            RSpec.configure do |config|
              config.expect_with :rspec do |expectations|
                expectations.strict_predicate_matchers = strict
              end
            end
          end

          context 'with non-strict matchers (default)' do
            let(:strict) { false }
            it { is_expected.to have_strange_result }
          end

          context 'with strict matchers' do
            let(:strict) { true }
            # deliberate failure
            it { is_expected.to have_strange_result }
          end
        end
        """
      When I run `rspec strict_or_not.rb`
      Then the output should contain "2 examples, 1 failure"
      And the output should contain "has_strange_result?` to return true, got 42"

    Scenario: calling private method with be_predicate causes error
      Given a file named "attempting_to_match_private_method_spec.rb" with:
       """ruby
       class WithPrivateMethods
         def secret?
           true
         end
         private :secret?
       end

       RSpec.describe 'private methods' do
         subject { WithPrivateMethods.new }

         # deliberate failure
         it { is_expected.to be_secret }
       end
       """
     When I run `rspec attempting_to_match_private_method_spec.rb`
     Then the output should contain "1 example, 1 failure"
     And the output should contain "`secret?` is a private method"

    Scenario: calling private method with have_predicate causes error
      Given a file named "attempting_to_match_private_method_spec.rb" with:
       """ruby
       class WithPrivateMethods
         def has_secret?
           true
         end
         private :has_secret?
       end

       RSpec.describe 'private methods' do
         subject { WithPrivateMethods.new }

         # deliberate failure
         it { is_expected.to have_secret }
       end
       """
     When I run `rspec attempting_to_match_private_method_spec.rb`
     Then the output should contain "1 example, 1 failure"
     And the output should contain "`has_secret?` is a private method"
