Feature: exclusion filters

  You can exclude examples from a run by declaring an exclusion filter and then
  tagging examples, or entire groups, with that filter. You can also specify
  metadata using only symbols.

  Scenario: Exclude an example
    Given a file named "spec/sample_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        # declare an exclusion filter
        c.filter_run_excluding :broken => true
      end

      RSpec.describe "something" do
        it "does one thing" do
        end

        # tag example for exclusion by adding metadata
        it "does another thing", :broken => true do
        end
      end
      """
    When I run `rspec ./spec/sample_spec.rb --format doc`
    Then the output should contain "does one thing"
    And the output should not contain "does another thing"

  Scenario: Exclude a group
    Given a file named "spec/sample_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.filter_run_excluding :broken => true
      end

      RSpec.describe "group 1", :broken => true do
        it "group 1 example 1" do
        end

        it "group 1 example 2" do
        end
      end

      RSpec.describe "group 2" do
        it "group 2 example 1" do
        end
      end
      """
    When I run `rspec ./spec/sample_spec.rb --format doc`
    Then the output should contain "group 2 example 1"
    And  the output should not contain "group 1 example 1"
    And  the output should not contain "group 1 example 2"

  Scenario: Exclude multiple groups
    Given a file named "spec/sample_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.filter_run_excluding :broken => true
      end

      RSpec.describe "group 1", :broken => true do
        before(:context) do
          raise "you should not see me"
        end

        it "group 1 example 1" do
        end

        it "group 1 example 2" do
        end
      end

      RSpec.describe "group 2", :broken => true do
        before(:example) do
          raise "you should not see me"
        end

        it "group 2 example 1" do
        end
      end
      """
    When I run `rspec ./spec/sample_spec.rb --format doc`
    Then the process should succeed even though no examples were run
    And  the output should not contain "group 1"
    And  the output should not contain "group 2"

  Scenario: `before`/`after(:context)` hooks in excluded example group are not run
    Given a file named "spec/before_after_context_exclusion_filter_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.filter_run_excluding :broken => true
      end

      RSpec.describe "group 1" do
        before(:context) { puts "before context in included group" }
        after(:context)  { puts "after context in included group"  }

        it "group 1 example" do
        end
      end

      RSpec.describe "group 2", :broken => true do
        before(:context) { puts "before context in excluded group" }
        after(:context)  { puts "after context in excluded group"  }

        context "context 1" do
          it "group 2 context 1 example 1" do
          end
        end
      end
      """
    When I run `rspec ./spec/before_after_context_exclusion_filter_spec.rb`
    Then the output should contain "before context in included group"
     And the output should contain "after context in included group"
     And the output should not contain "before context in excluded group"
     And the output should not contain "after context in excluded group"

  Scenario: Use symbols as metadata
    Given a file named "symbols_as_metadata_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.filter_run_excluding :broken
      end

      RSpec.describe "something" do
        it "does one thing" do
        end

        # tag example for exclusion by adding metadata
        it "does another thing", :broken do
        end
      end
      """
    When I run `rspec symbols_as_metadata_spec.rb --format doc`
    Then the output should contain "does one thing"
    And the output should not contain "does another thing"
