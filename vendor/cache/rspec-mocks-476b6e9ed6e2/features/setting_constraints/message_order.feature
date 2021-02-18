Feature: Message Order

  You can use `ordered` to constrain the order of multiple message expectations. This is not
  generally recommended because in most situations the order doesn't matter and using
  `ordered` would make your spec brittle, but it's occasionally useful. When you use `ordered`,
  the example will only pass if the messages are received in the declared order.

  Scenario: Passing example
    Given a file named "passing_example_spec.rb" with:
      """ruby
      RSpec.describe "Constraining order" do
        it "passes when the messages are received in declared order" do
          collaborator_1 = double("Collaborator 1")
          collaborator_2 = double("Collaborator 2")

          expect(collaborator_1).to receive(:step_1).ordered
          expect(collaborator_2).to receive(:step_2).ordered
          expect(collaborator_1).to receive(:step_3).ordered

          collaborator_1.step_1
          collaborator_2.step_2
          collaborator_1.step_3
        end
      end
      """
    When I run `rspec passing_example_spec.rb`
    Then the examples should all pass

  Scenario: Failing examples
    Given a file named "failing_examples_spec.rb" with:
      """ruby
      RSpec.describe "Constraining order" do
        it "fails when messages are received out of order on one collaborator" do
          collaborator_1 = double("Collaborator 1")

          expect(collaborator_1).to receive(:step_1).ordered
          expect(collaborator_1).to receive(:step_2).ordered

          collaborator_1.step_2
          collaborator_1.step_1
        end

        it "fails when messages are received out of order between collaborators" do
          collaborator_1 = double("Collaborator 1")
          collaborator_2 = double("Collaborator 2")

          expect(collaborator_1).to receive(:step_1).ordered
          expect(collaborator_2).to receive(:step_2).ordered

          collaborator_2.step_2
          collaborator_1.step_1
        end
      end
      """
    When I run `rspec failing_examples_spec.rb --order defined`
    Then the examples should all fail, producing the following output:
      |  1) Constraining order fails when messages are received out of order on one collaborator   |
      |     Failure/Error: collaborator_1.step_2                                                   |
      |       #<Double "Collaborator 1"> received :step_2 out of order                             |
      |                                                                                            |
      |  2) Constraining order fails when messages are received out of order between collaborators |
      |     Failure/Error: collaborator_2.step_2                                                   |
      |       #<Double "Collaborator 2"> received :step_2 out of order                             |
