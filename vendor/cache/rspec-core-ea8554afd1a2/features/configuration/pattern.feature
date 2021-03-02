Feature: pattern

  Use the `pattern` option to configure RSpec to look for specs in files that match
  a pattern instead of the default `"**/*_spec.rb"`.

  ```ruby
  RSpec.configure { |c| c.pattern = '**/*.spec' }
  ```

  Rather than using `require 'spec_helper'` at the top of each spec file,
  ensure that you have `--require spec_helper` in `.rspec`. That will always
  load before the pattern is resolved. With the pattern thus configured,
  only those spec files that match the pattern will then be loaded.

  Background:
    Given a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "two specs" do
        it "passes" do
        end

        it "passes too" do
        end
      end
      """

  Scenario: Override the default pattern in configuration
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |config|
        config.pattern = '**/*.spec'
      end
      """
    And a file named "spec/one_example.spec" with:
      """ruby
      RSpec.describe "something" do
        it "passes" do
        end
      end
      """
    When I run `rspec -rspec_helper`
    Then the output should contain "1 example, 0 failures"

  Scenario: Append to the default pattern in configuration
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |config|
        config.pattern += ',**/*.spec'
      end
      """
    And a file named "spec/two_examples.spec" with:
      """ruby
      RSpec.describe "something" do
        it "passes" do
        end

        it "passes again" do
        end
      end
      """
    When I run `rspec -rspec_helper`
    Then the output should contain "4 examples, 0 failures"
