Feature: Custom output stream

  Define a custom output stream (default `$stdout`).  Aliases: `:output`,
  `:out`.

  ```ruby
  RSpec.configure { |c| c.output_stream = File.open('saved_output', 'w') }
  ```

  Background:
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure { |c| c.output_stream = File.open('saved_output', 'w') }
      """

  Scenario: Redirecting output
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require 'spec_helper'
      RSpec.describe "an example" do
        it "passes" do
          true
        end
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the file "saved_output" should contain "1 example, 0 failures"
