Feature: `when_first_matching_example_defined` hook

  In large projects that use RSpec, it's common to have some expensive setup logic
  that is only needed when certain kinds of specs have been loaded. If that kind of
  spec has not been loaded, you'd prefer to avoid the cost of doing the setup.

  The `when_first_matching_example_defined` hook makes it easy to conditionally
  perform some logic when the first example is defined with matching metadata,
  allowing you to ensure the necessary setup is performed only when needed.

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |config|
        config.when_first_matching_example_defined(:db) do
          require "support/db"
        end
      end
      """
    And a file named "spec/support/db.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:suite) do
          puts "Bootstrapped the DB."
        end

        config.around(:example, :db) do |example|
          puts "Starting a DB transaction."
          example.run
          puts "Rolling back a DB transaction."
        end
      end
      """
    And a file named ".rspec" with:
      """
      --require spec_helper
      """
    And a file named "spec/unit_spec.rb" with:
      """
      RSpec.describe "A unit spec" do
        it "does not require a database" do
          puts "in unit example"
        end
      end
      """
    And a file named "spec/integration_spec.rb" with:
      """
      RSpec.describe "An integration spec", :db do
        it "requires a database" do
          puts "in integration example"
        end
      end
      """

  Scenario: Running the entire suite loads the DB setup
    When I run `rspec`
    Then it should pass with:
      """
      Bootstrapped the DB.
      Starting a DB transaction.
      in integration example
      Rolling back a DB transaction.
      .in unit example
      .
      """

  Scenario: Running just the unit spec does not load the DB setup
    When I run `rspec spec/unit_spec.rb`
    Then the examples should all pass
    And the output should not contain "DB"
