Feature: Expecting messages

  Use `expect(...).to receive(...)` to expect a message on a [test double](./test-doubles). Unfulfilled
  message expectations trigger failures when the example completes. You can also use
  `expect(...).not_to receive(...)` to set a negative message expectation.

  Scenario: Failing positive message expectation
    Given a file named "unfulfilled_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "An unfulfilled positive message expectation" do
        it "triggers a failure" do
          dbl = double("Some Collaborator")
          expect(dbl).to receive(:foo)
        end
      end
      """
     When I run `rspec unfulfilled_message_expectation_spec.rb`
     Then it should fail with:
      """
        1) An unfulfilled positive message expectation triggers a failure
           Failure/Error: expect(dbl).to receive(:foo)

             (Double "Some Collaborator").foo(*(any args))
                 expected: 1 time with any arguments
                 received: 0 times with any arguments
      """

  Scenario: Passing positive message expectation
    Given a file named "fulfilled_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A fulfilled positive message expectation" do
        it "passes" do
          dbl = double("Some Collaborator")
          expect(dbl).to receive(:foo)
          dbl.foo
        end
      end
      """
     When I run `rspec fulfilled_message_expectation_spec.rb`
     Then the examples should all pass

  Scenario: Failing negative message expectation
    Given a file named "negative_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A negative message expectation" do
        it "fails when the message is received" do
          dbl = double("Some Collaborator").as_null_object
          expect(dbl).not_to receive(:foo)
          dbl.foo
        end
      end
      """
     When I run `rspec negative_message_expectation_spec.rb`
     Then it should fail with:
      """
        1) A negative message expectation fails when the message is received
           Failure/Error: dbl.foo

             (Double "Some Collaborator").foo(no args)
                 expected: 0 times with any arguments
                 received: 1 time
      """

  Scenario: Passing negative message expectation
    Given a file named "negative_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A negative message expectation" do
        it "passes if the message is never received" do
          dbl = double("Some Collaborator").as_null_object
          expect(dbl).not_to receive(:foo)
        end
      end
      """
     When I run `rspec negative_message_expectation_spec.rb`
     Then the examples should all pass

  Scenario: Failing positive message expectation with a custom failure message
    Given a file named "example_spec.rb" with:
    """ruby
    RSpec.describe "An unfulfilled positive message expectation" do
      it "triggers a failure" do
        dbl = double
        expect(dbl).to receive(:foo), "dbl never calls :foo"
      end
    end
    """
    When I run `rspec example_spec.rb --format documentation`
    Then the output should contain:
    """
      1) An unfulfilled positive message expectation triggers a failure
         Failure/Error: expect(dbl).to receive(:foo), "dbl never calls :foo"
           dbl never calls :foo
    """

  Scenario: Failing negative message expectation with a custom failure message
    Given a file named "example_spec.rb" with:
    """ruby
    RSpec.describe "A negative message expectation" do
      it "fails when the message is received" do
        dbl = double
        expect(dbl).not_to receive(:foo), "dbl called :foo but is not supposed to"
        dbl.foo
      end
    end
    """
    When I run `rspec example_spec.rb --format documentation`
    Then the output should contain:
    """
      1) A negative message expectation fails when the message is received
         Failure/Error: dbl.foo
           dbl called :foo but is not supposed to
    """
