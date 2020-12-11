Feature: exclude_pattern

  Use the `--exclude-pattern` option to tell RSpec to skip looking for specs in files
  that match the pattern specified.

  Background:
    Given a file named "spec/models/model_spec.rb" with:
      """ruby
      RSpec.describe "two specs here" do
        it "passes" do
        end

        it "passes too" do
        end
      end
      """
    And a file named "spec/features/feature_spec.rb" with:
      """ruby
      RSpec.describe "only one spec" do
        it "passes" do
        end
      end
      """

  Scenario: By default, RSpec runs files that match `"**/*_spec.rb"`
   When I run `rspec`
   Then the output should contain "3 examples, 0 failures"

  Scenario: The `--exclude-pattern` flag makes RSpec skip matching files
   When I run `rspec --exclude-pattern "**/models/*_spec.rb"`
   Then the output should contain "1 example, 0 failures"

  Scenario: The `--exclude-pattern` flag can be used to pass in multiple patterns, separated by comma
   When I run `rspec --exclude-pattern "**/models/*_spec.rb, **/features/*_spec.rb"`
   Then the output should contain "0 examples, 0 failures"

  Scenario: The `--exclude-pattern` flag accepts shell style glob unions
   When I run `rspec --exclude-pattern "**/{models,features}/*_spec.rb"`
   Then the output should contain "0 examples, 0 failures"

  Scenario: The `--exclude-pattern` flag can be used with the `--pattern` flag
   When I run `rspec --pattern "spec/**/*_spec.rb" --exclude-pattern "spec/models/*_spec.rb"`
   Then the output should contain "1 example, 0 failures"
