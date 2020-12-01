Feature: `--fail-fast` option

  Use the `--fail-fast` option to tell RSpec to stop running the test suite on
  the first failed test.

  You may add a parameter to tell RSpec to stop running the test suite after N
  failed tests, for example: `--fail-fast=3`.

  You can also specify `--no-fail-fast` to turn it off (default behaviour).

  Background:
    Given a file named "fail_fast_spec.rb" with:
      """ruby
      RSpec.describe "fail fast" do
        it "passing test" do; end
        it "1st failing test" do
          fail
        end
        it "2nd failing test" do
          fail
        end
        it "3rd failing test" do
          fail
        end
        it "4th failing test" do
          fail
        end
        it "passing test" do; end
      end
      """

  Scenario: Using `--fail-fast`
    When I run `rspec . --fail-fast`
    Then the output should contain ".F"
    Then the output should not contain ".F."

  Scenario: Using `--fail-fast=3`
    When I run `rspec . --fail-fast=3`
    Then the output should contain ".FFF"
    Then the output should not contain ".FFFF."

  Scenario: Using `--no-fail-fast`
    When I run `rspec . --no-fail-fast`
    Then the output should contain ".FFFF."
