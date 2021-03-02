Feature: `--dry-run` option

  Use the `--dry-run` option to have RSpec print your suite's formatter output
  without running any examples or hooks.

  Scenario: Using `--dry-run`
    Given a file named "spec/dry_run_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.before(:suite) { puts "before suite" }
        c.after(:suite)  { puts "after suite"  }
      end

      RSpec.describe "dry run" do
        before(:context) { fail }
        before(:example) { fail }

        it "fails in example" do
          fail
        end

        after(:example) { fail }
        after(:context) { fail }
      end
      """
    When I run `rspec --dry-run`
    Then the output should contain "1 example, 0 failures"
     And the output should not contain "before suite"
     And the output should not contain "after suite"
