Feature: error exit code

  Use the `error_exit_code` option to set a custom exit code when RSpec fails outside an example.

  ```ruby
  RSpec.configure { |c| c.error_exit_code = 42 }
  ```

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure { |c| c.error_exit_code = 42 }
      """

  Scenario: A erroring spec with the default exit code
    Given a file named "spec/typo_spec.rb" with:
      """ruby
      RSpec.escribe "something" do # intentional typo
        it "works" do
          true
        end
      end
      """
    When I run `rspec spec/typo_spec.rb`
    Then the exit status should be 1

  Scenario: A erroring spec with a custom exit code
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
    And  the exit status should be 42


  Scenario: Success running specs spec with a custom error exit code defined
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
