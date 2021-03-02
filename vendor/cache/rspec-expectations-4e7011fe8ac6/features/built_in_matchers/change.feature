Feature: `change` matcher

  The `change` matcher is used to specify that a block of code changes some mutable state.
  You can specify what will change using either of two forms:

  * `expect { do_something }.to change(object, :attribute)`
  * `expect { do_something }.to change { object.attribute }`

  You can further qualify the change by chaining `from` and/or `to` or one of `by`, `by_at_most`,
  `by_at_least`.

  Background:
    Given a file named "lib/counter.rb" with:
      """ruby
      class Counter
        class << self
          def increment
            @count ||= 0
            @count += 1
          end

          def count
            @count ||= 0
          end
        end
      end
      """

  @skip-when-ripper-unsupported
  Scenario: expect change
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require "counter"

      RSpec.describe Counter, "#increment" do
        it "should increment the count" do
          expect { Counter.increment }.to change { Counter.count }.from(0).to(1)
        end

        # deliberate failure
        it "should increment the count by 2" do
          expect { Counter.increment }.to change { Counter.count }.by(2)
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the output should contain "1 failure"
    Then the output should contain "expected `Counter.count` to have changed by 2, but was changed by 1"

  @skip-when-ripper-unsupported
  Scenario: expect no change
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require "counter"

      RSpec.describe Counter, "#increment" do
        it "should not increment the count by 1 (using not_to)" do
          expect { Counter.increment }.not_to change { Counter.count }
        end

        it "should not increment the count by 1 (using to_not)" do
          expect { Counter.increment }.to_not change { Counter.count }
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the output should contain "2 failures"
    Then the output should contain "expected `Counter.count` not to have changed, but did change from 1 to 2"
