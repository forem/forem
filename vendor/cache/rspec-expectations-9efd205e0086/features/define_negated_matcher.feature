Feature: Define negated matcher

  You can use `RSpec::Matchers.define_negated_matcher` to define a negated version of
  an existing matcher. This is particularly useful in composed matcher expressions.

  @skip-when-ripper-unsupported
  Scenario: Composed negated matcher expression
    Given a file named "composed_negated_expression_spec.rb" with:
      """ruby
      RSpec::Matchers.define_negated_matcher :an_array_excluding, :include

      RSpec.describe "A negated matcher" do
        let(:list) { 1.upto(10).to_a }

        it "can be used in a composed matcher expression" do
          expect { list.delete(5) }.to change { list }.to(an_array_excluding 5)
        end

        it "provides a good failure message based on the name" do
          # deliberate failure
          expect { list.delete(1) }.to change { list }.to(an_array_excluding 5)
        end
      end
      """
    When I run `rspec composed_negated_expression_spec.rb`
    Then the output should contain all of these:
      | 2 examples, 1 failure                                                                                  |
      |  1) A negated matcher provides a good failure message based on the name                                |
      |     Failure/Error: expect { list.delete(1) }.to change { list }.to(an_array_excluding 5)               |
      |       expected `list` to have changed to an array excluding 5, but is now [2, 3, 4, 5, 6, 7, 8, 9, 10] |
