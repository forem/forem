Feature: Setting the default spec path

  You can just type `rspec` to run all specs that live in the `spec` directory.

  This is supported by a `--default-path` option, which is set to `spec` by
  default. If you prefer to keep your specs in a different directory, or assign
  an individual file to `--default-path`, you can do so on the command line or
  in a configuration file (for example `.rspec`).

  **NOTE:** this option is not supported on `RSpec.configuration`, as it needs to be
  set before spec files are loaded.

  Scenario: Run `rspec` with default `default-path` (`spec` directory)
    Given a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        it "passes" do
        end
      end
      """
    When I run `rspec`
    Then the output should contain "1 example, 0 failures"

  Scenario: Run `rspec` with customized `default-path`
    Given a file named ".rspec" with:
      """
      --default-path behavior
      """
    Given a file named "behavior/example_spec.rb" with:
      """ruby
      RSpec.describe "an example" do
        it "passes" do
        end
      end
      """
    When I run `rspec`
    Then the output should contain "1 example, 0 failures"
