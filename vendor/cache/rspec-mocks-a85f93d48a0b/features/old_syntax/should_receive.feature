@allow-old-syntax
Feature: `should_receive`

  `should_receive` is the old way to [expect messages](../basics/expecting-messages) but carries the
  baggage of a global monkey patch on all objects. It supports the
  same fluent interface for [setting constraints](../setting-constraints) and [configuring responses](../configuring-responses).

  Similarly, you can use `should_not_receive` to set a negative message expectation.

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :rspec do |mocks|
          mocks.syntax = :should
        end
      end
      """
    And a file named ".rspec" with:
      """
      --require spec_helper
      """

  Scenario: Failing positive message expectation
    Given a file named "spec/unfulfilled_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "An unfulfilled message expectation" do
        it "triggers a failure" do
          dbl = double("Some Collaborator")
          dbl.should_receive(:foo)
        end
      end
      """
     When I run `rspec spec/unfulfilled_message_expectation_spec.rb`
     Then it should fail with:
      """
        1) An unfulfilled message expectation triggers a failure
           Failure/Error: dbl.should_receive(:foo)

             (Double "Some Collaborator").foo(*(any args))
                 expected: 1 time with any arguments
                 received: 0 times with any arguments
      """

  Scenario: Passing positive message expectation
    Given a file named "spec/fulfilled_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A fulfilled message expectation" do
        it "passes" do
          dbl = double("Some Collaborator")
          dbl.should_receive(:foo)
          dbl.foo
        end
      end
      """
     When I run `rspec spec/fulfilled_message_expectation_spec.rb`
     Then the examples should all pass

  Scenario: Failing negative message expectation
    Given a file named "spec/negative_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A negative message expectation" do
        it "fails when the message is received" do
          dbl = double("Some Collaborator").as_null_object
          dbl.should_not_receive(:foo)
          dbl.foo
        end
      end
      """
     When I run `rspec spec/negative_message_expectation_spec.rb`
     Then it should fail with:
      """
        1) A negative message expectation fails when the message is received
           Failure/Error: dbl.foo

             (Double "Some Collaborator").foo(no args)
                 expected: 0 times with any arguments
                 received: 1 time
      """

  Scenario: Passing negative message expectation
    Given a file named "spec/negative_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A negative message expectation" do
        it "passes if the message is never received" do
          dbl = double("Some Collaborator").as_null_object
          dbl.should_not_receive(:foo)
        end
      end
      """
     When I run `rspec spec/negative_message_expectation_spec.rb`
     Then the examples should all pass
