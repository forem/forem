Feature: Compound Expectations

  Matchers can be composed using `and` or `or` to make compound expectations.

  Scenario: Use `and` to chain expectations
    Given a file named "compound_and_matcher_spec.rb" with:
      """ruby
      RSpec.describe "A compound `and` matcher" do
        let(:string) { "foo bar bazz" }

        it "passes when both are true" do
          expect(string).to start_with("foo").and end_with("bazz")
        end

        it "passes when using boolean AND `&` alias" do
          expect(string).to start_with("foo") & end_with("bazz")
        end

        it "fails when the first matcher fails" do
          expect(string).to start_with("bar").and end_with("bazz")
        end

        it "fails when the second matcher fails" do
          expect(string).to start_with("foo").and end_with("bar")
        end
      end
      """
    When I run `rspec compound_and_matcher_spec.rb`
    Then the output should contain "4 examples, 2 failures"

  Scenario: Use `or` to chain expectations
    Given a file named "stoplight_spec.rb" with:
      """ruby
      class StopLight
        def color
          %w[ green yellow red ].shuffle.first
        end
      end

      RSpec.describe StopLight, "#color" do
        let(:light) { StopLight.new }
        it "is green, yellow or red" do
          expect(light.color).to eq("green").or eq("yellow").or eq("red")
        end

        it "passes when using boolean OR `|` alias" do
          expect(light.color).to eq("green") | eq("yellow") | eq("red")
        end
      end
      """
    When I run `rspec stoplight_spec.rb`
    Then the example should pass
