Feature: `around` hooks

  `around` hooks receive the example as a block argument, extended to behave as
  a proc. This lets you define code that should be executed before and after the
  example. Of course, you can do the same thing with `before` and `after` hooks;
  and it's often cleaner to do so.

  Where `around` hooks shine is when you want to run an example within a block.
  For instance, if your database library offers a transaction method that
  receives a block, you can use an `around` to cleanly open and close the
  transaction around the example.

  **WARNING:** `around` hooks do not share state with the example the way
  `before` and `after` hooks do. This means that you cannot share instance
  variables between `around` hooks and examples.

  **WARNING:** Mock frameworks are set up and torn down within the context of
  running the example. You cannot interact with them directly in `around` hooks.

  **WARNING:** `around` hooks will execute *before* any `before` hooks, and *after*
  any `after` hooks regardless of the context they were defined in.

  Scenario: Use the example as a proc within the block passed to `around()`
    Given a file named "example_spec.rb" with:
      """ruby
      class Database
        def self.transaction
          puts "open transaction"
          yield
          puts "close transaction"
        end
      end

      RSpec.describe "around filter" do
        around(:example) do |example|
          Database.transaction(&example)
        end

        it "gets run in order" do
          puts "run the example"
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain:
      """
      open transaction
      run the example
      close transaction
      """

  Scenario: Invoke the example using `run()`
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "around hook" do
        around(:example) do |example|
          puts "around example before"
          example.run
          puts "around example after"
        end

        it "gets run in order" do
          puts "in the example"
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain:
      """
      around example before
      in the example
      around example after
      """

  Scenario: Access the example metadata
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        around(:example) do |example|
          puts example.metadata[:foo]
          example.run
        end

        it "does something", :foo => "this should show up in the output" do
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "this should show up in the output"

  Scenario: An around hook continues to run even if the example throws an exception
    Given a file named "example_spec.rb" with:
      """ruby
        RSpec.describe "something" do
          around(:example) do |example|
            puts "around example setup"
            example.run
            puts "around example cleanup"
          end

          it "still executes the entire around hook" do
            fail "the example blows up"
          end
        end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 1 failure"
    And the output should contain:
      """
      around example setup
      around example cleanup
      """

  Scenario: Define a global `around` hook
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.around(:example) do |example|
          puts "around example before"
          example.run
          puts "around example after"
        end
      end

      RSpec.describe "around filter" do
        it "gets run in order" do
          puts "in the example"
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain:
      """
      around example before
      in the example
      around example after
      """

  Scenario: Per example hooks are wrapped by the `around` hook
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "around filter" do
        around(:example) do |example|
          puts "around example before"
          example.run
          puts "around example after"
        end

        before(:example) do
          puts "before example"
        end

        after(:example) do
          puts "after example"
        end

        it "gets run in order" do
          puts "in the example"
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain:
      """
      around example before
      before example
      in the example
      after example
      around example after
      """

  Scenario: Context hooks are NOT wrapped by the `around` hook
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "around filter" do
        around(:example) do |example|
          puts "around example before"
          example.run
          puts "around example after"
        end

        before(:context) do
          puts "before context"
        end

        after(:context) do
          puts "after context"
        end

        it "gets run in order" do
          puts "in the example"
        end
      end
      """
    When I run `rspec --format progress example_spec.rb`
    Then the output should contain:
      """
      before context
      around example before
      in the example
      around example after
      .after context
      """

  Scenario: Examples run by an `around` block are run in the configured context
    Given a file named "example_spec.rb" with:
      """ruby
      module IncludedInConfigureBlock
        def included_in_configure_block; true; end
      end

      RSpec.configure do |c|
        c.include IncludedInConfigureBlock
      end

      RSpec.describe "around filter" do
        around(:example) do |example|
          example.run
        end

        it "runs the example in the correct context" do
          expect(included_in_configure_block).to be(true)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 0 failure"

  Scenario: Implicitly pending examples are detected as Not yet implemented
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "implicit pending example" do
        around(:example) do |example|
          example.run
        end

        it "should be detected as Not yet implemented"
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) implicit pending example should be detected as Not yet implemented
           # Not yet implemented
           # ./example_spec.rb:6
      """


  Scenario: Explicitly pending examples are detected as pending
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "explicit pending example" do
        around(:example) do |example|
          example.run
        end

        it "should be detected as pending" do
          pending
          fail
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) explicit pending example should be detected as pending
           # No reason given
      """

  Scenario: Multiple `around` hooks in the same scope
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "if there are multiple around hooks in the same scope" do
        around(:example) do |example|
          puts "first around hook before"
          example.run
          puts "first around hook after"
        end

        around(:example) do |example|
          puts "second around hook before"
          example.run
          puts "second around hook after"
        end

        it "they should all be run" do
          puts "in the example"
          expect(1).to eq(1)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 0 failure"
    And the output should contain:
      """
      first around hook before
      second around hook before
      in the example
      second around hook after
      first around hook after
      """

  Scenario: `around` hooks in multiple scopes
    Given a file named "example_spec.rb" with:
    """ruby
    RSpec.describe "if there are around hooks in an outer scope" do
      around(:example) do |example|
        puts "first outermost around hook before"
        example.run
        puts "first outermost around hook after"
      end

      around(:example) do |example|
        puts "second outermost around hook before"
        example.run
        puts "second outermost around hook after"
      end

      describe "outer scope" do
        around(:example) do |example|
          puts "first outer around hook before"
          example.run
          puts "first outer around hook after"
        end

        around(:example) do |example|
          puts "second outer around hook before"
          example.run
          puts "second outer around hook after"
        end

        describe "inner scope" do
          around(:example) do |example|
            puts "first inner around hook before"
            example.run
            puts "first inner around hook after"
          end

          around(:example) do |example|
            puts "second inner around hook before"
            example.run
            puts "second inner around hook after"
          end

          it "they should all be run" do
            puts "in the example"
          end
        end
      end
    end
    """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 0 failure"
    And the output should contain:
    """
    first outermost around hook before
    second outermost around hook before
    first outer around hook before
    second outer around hook before
    first inner around hook before
    second inner around hook before
    in the example
    second inner around hook after
    first inner around hook after
    second outer around hook after
    first outer around hook after
    second outermost around hook after
    first outermost around hook after
    """
