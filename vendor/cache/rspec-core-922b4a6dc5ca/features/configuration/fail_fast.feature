Feature: fail fast

  Use the `fail_fast` option to tell RSpec to abort the run after N failures:

  Scenario: `fail_fast` with no failures (runs all examples)
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure {|c| c.fail_fast = 1}
      """
    And a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "passes" do
        end

        it "passes too" do
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the examples should all pass

  Scenario: `fail_fast` with first example failing (only runs the one example)
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure {|c| c.fail_fast = 1}
      """
    And a file named "spec/example_spec.rb" with:
      """ruby
      require "spec_helper"
      RSpec.describe "something" do
        it "fails" do
          fail
        end

        it "passes" do
        end
      end
      """
    When I run `rspec spec/example_spec.rb -fd`
    Then the output should contain "1 example, 1 failure"

  Scenario: `fail_fast` with multiple files, second example failing (only runs the first two examples)
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure {|c| c.fail_fast = 1}
      """
    And a file named "spec/example_1_spec.rb" with:
      """ruby
      require "spec_helper"
      RSpec.describe "something" do
        it "passes" do
        end

        it "fails" do
          fail
        end
      end

      RSpec.describe "something else" do
        it "fails" do
          fail
        end
      end
      """
    And a file named "spec/example_2_spec.rb" with:
      """ruby
      require "spec_helper"
      RSpec.describe "something" do
        it "passes" do
        end
      end

      RSpec.describe "something else" do
        it "fails" do
          fail
        end
      end
      """
    When I run `rspec spec`
    Then the output should contain "2 examples, 1 failure"


  Scenario: `fail_fast 2` with 1st and 3rd examples failing (only runs the first 3 examples)
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure {|c| c.fail_fast = 2}
      """
    And a file named "spec/example_spec.rb" with:
      """ruby
      require "spec_helper"
      RSpec.describe "something" do
        it "fails once" do
          fail
        end

        it "passes once" do
        end

        it "fails twice" do
          fail
        end

        it "passes" do
        end
      end
      """
    When I run `rspec spec/example_spec.rb -fd`
    Then the output should contain "3 examples, 2 failures"
