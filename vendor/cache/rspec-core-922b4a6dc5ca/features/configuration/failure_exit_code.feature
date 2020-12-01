Feature: failure exit code

  Use the `failure_exit_code` option to set a custom exit code when RSpec fails.

  ```ruby
  RSpec.configure { |c| c.failure_exit_code = 42 }
  ```

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure { |c| c.failure_exit_code = 42 }
      """

  Scenario: A failing spec with the default exit code
    Given a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "fails" do
          fail
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the exit status should be 1

  Scenario: A failing spec with a custom exit code
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require 'spec_helper'
      RSpec.describe "something" do
        it "fails" do
          fail
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the exit status should be 42

  Scenario: An error running specs spec with a custom exit code
    Given a file named "spec/typo_spec.rb" with:
      """ruby
      require 'spec_helper'
      RSpec.escribe "something" do # intentional typo
        it "works" do
          true
        end
      end
      """
    When I run `rspec spec/typo_spec.rb`
    Then the exit status should be 42

  Scenario: Success running specs spec with a custom exit code defined
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require 'spec_helper'
      RSpec.describe "something" do
        it "works" do
          true
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the exit status should be 0

  Scenario: Exit with the default exit code when an `at_exit` hook is added upstream
    Given a file named "exit_at_spec.rb" with:
      """ruby
      require 'rspec/autorun'
      at_exit { exit(0) }

      RSpec.describe "exit 0 at_exit ignored" do
        it "does not interfere with the default exit code" do
          fail
        end
      end
      """
    When I run `ruby exit_at_spec.rb`
    Then the exit status should be 1
