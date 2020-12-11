Feature: `--format` option

  Use the `--format` option to tell RSpec how to format the output.

  RSpec ships with several formatters built in. By default, it uses the progress
  formatter, which generates output like this:

      ....F.....*.....

  A '.' represents a passing example, 'F' is failing, and '*' is pending.

  Use the documentation formatter to see the documentation strings passed to
  `describe`, `it`, and their aliases:

  ```bash
  $ rspec spec --format documentation
  ```

  You can also specify an output target (`$stdout` by default) with an `--out`
  option immediately following the `--format` option:

  ```bash
  $ rspec spec --format documentation --out rspec.txt
  ```

  Run `rspec --help` to see a listing of available formatters.

  Background:
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe "something" do
        it "does something that passes" do
          expect(5).to eq(5)
        end

        it "does something that fails" do
          expect(5).to eq(4)
        end

        it "does something that is pending", :pending => true do
          expect(5).to be < 3
        end

        it "does something that is skipped", :skip => true do
          expect(5).to be < 3
        end
      end
      """

  Scenario: Progress bar format (default)
    When I run `rspec --format progress example_spec.rb`
    Then the output should contain ".F**"

  Scenario: Documentation format
    When I run `rspec example_spec.rb --format documentation`
    Then the output should contain:
      """
      something
        does something that passes
        does something that fails (FAILED - 1)
        does something that is pending (PENDING: No reason given)
        does something that is skipped (PENDING: No reason given)
      """

  Scenario: Documentation format saved to a file
    When I run `rspec example_spec.rb --format documentation --out rspec.txt`
    Then the file "rspec.txt" should contain:
      """
      something
        does something that passes
        does something that fails (FAILED - 1)
        does something that is pending (PENDING: No reason given)
        does something that is skipped (PENDING: No reason given)
      """

  Scenario: Multiple formats and output targets
    When I run `rspec example_spec.rb --format progress --format documentation --out rspec.txt`
    Then the output should contain ".F**"
    And the file "rspec.txt" should contain:
      """
      something
        does something that passes
        does something that fails (FAILED - 1)
        does something that is pending (PENDING: No reason given)
        does something that is skipped (PENDING: No reason given)
      """
