Feature: Custom deprecation stream

  Define a custom output stream for warning about deprecations (default
  `$stderr`).

  ```ruby
  RSpec.configure do |c|
    c.deprecation_stream = File.open('deprecations.txt', 'w')
  end
  ```

  or

  ```ruby
  RSpec.configure { |c| c.deprecation_stream = 'deprecations.txt' }
  ```

  or pass `--deprecation-out`

  Background:
    Given a file named "lib/foo.rb" with:
      """ruby
      class Foo
        def bar
          RSpec.deprecate "Foo#bar"
        end
      end
      """

  Scenario: Default - print deprecations to `$stderr`
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require "foo"

      RSpec.describe "calling a deprecated method" do
        example { Foo.new.bar }
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the output should contain "Deprecation Warnings:\n\nFoo#bar is deprecated"

  Scenario: Configure using the path to a file
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require "foo"

      RSpec.configure {|c| c.deprecation_stream = 'deprecations.txt' }

      RSpec.describe "calling a deprecated method" do
        example { Foo.new.bar }
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the output should not contain "Deprecation Warnings:"
    But the output should contain "1 deprecation logged to deprecations.txt"
    And the file "deprecations.txt" should contain "Foo#bar is deprecated"

  Scenario: Configure using a `File` object
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require "foo"

      RSpec.configure do |c|
        c.deprecation_stream = File.open('deprecations.txt', 'w')
      end

      RSpec.describe "calling a deprecated method" do
        example { Foo.new.bar }
      end
      """
    When I run `rspec spec/example_spec.rb`
    Then the output should not contain "Deprecation Warnings:"
    But the output should contain "1 deprecation logged to deprecations.txt"
    And the file "deprecations.txt" should contain "Foo#bar is deprecated"

  Scenario: configure using the CLI `--deprecation-out` option
    Given a file named "spec/example_spec.rb" with:
      """ruby
      require "foo"
      RSpec.describe "calling a deprecated method" do
        example { Foo.new.bar }
      end
      """
    When I run `rspec spec/example_spec.rb --deprecation-out deprecations.txt`
    Then the output should not contain "Deprecation Warnings:"
    But the output should contain "1 deprecation logged to deprecations.txt"
    And the file "deprecations.txt" should contain "Foo#bar is deprecated"
