Feature: Create example aliases

  Use `config.alias_example_to` to create new example group methods that define
  examples with the configured metadata. You can also specify metadata using
  only symbols.

  Scenario: Use `alias_example_to` to define a custom example name
    Given a file named "alias_example_to_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.alias_example_to :task
      end

      RSpec.describe "a task example group" do
        task "does something" do
          expect(5).to eq(5)
        end
      end
      """
    When I run `rspec alias_example_to_spec.rb --format doc`
    Then the output should contain "does something"
    And the examples should all pass


  Scenario: Use `alias_example_to` to define a pending example
    Given a file named "alias_example_to_pending_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.alias_example_to :pit, :pending => "Pit alias used"
      end

      RSpec.describe "an example group" do
        pit "does something later on" do
          fail "not implemented yet"
        end
      end
      """
    When I run `rspec alias_example_to_pending_spec.rb --format doc`
    Then the output should contain "does something later on (PENDING: Pit alias used)"
    And the output should contain "0 failures"

  Scenario: Use symbols as metadata
    Given a file named "use_symbols_as_metadata_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.alias_example_to :pit, :pending
      end

      RSpec.describe "an example group" do
        pit "does something later on" do
          fail "not implemented yet"
        end
      end
      """
    When I run `rspec use_symbols_as_metadata_spec.rb --format doc`
    Then the output should contain "does something later on (PENDING: No reason given)"
    And the output should contain "0 failures"
