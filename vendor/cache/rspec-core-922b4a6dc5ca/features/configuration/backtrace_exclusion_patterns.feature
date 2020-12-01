Feature: Excluding lines from the backtrace

  To reduce the noise when diagnosing failures, RSpec can exclude lines belonging to certain gems or matching given patterns.

  If you want to filter out backtrace lines belonging to specific gems, you can use `config.filter_gems_from_backtrace` like so:

  ```ruby
  config.filter_gems_from_backtrace "ignored_gem", "another_ignored_gem",
  ```

  For more control over which lines to ignore, you can use the the `backtrace_exclusion_patterns` option to either replace the default exclusion patterns, or append your own, e.g.

  ```ruby
  config.backtrace_exclusion_patterns = [/first pattern/, /second pattern/]
  config.backtrace_exclusion_patterns << /another pattern/
  ```

  The default exclusion patterns are:

  ```ruby
  /\/lib\d*\/ruby\//,
  /org\/jruby\//,
  /bin\//,
  /lib\/rspec\/(core|expectations|matchers|mocks)/
  ```

  Additionally, `rspec` can be run with the `--backtrace` option to skip backtrace cleaning entirely.


  Scenario: Using default `backtrace_exclusion_patterns`
    Given a file named "spec/failing_spec.rb" with:
    """ruby
    RSpec.describe "2 + 2" do
      it "is 5" do
        expect(2+2).to eq(5)
      end
    end
    """
    When I run `rspec`
    Then the output should contain "1 example, 1 failure"
    And the output should not contain "lib/rspec/expectations"

  Scenario: Replacing `backtrace_exclusion_patterns`
    Given a file named "spec/spec_helper.rb" with:
    """ruby
    RSpec.configure do |config|
      config.backtrace_exclusion_patterns = [
        /spec_helper/
      ]
    end
    """
    And a file named "spec/example_spec.rb" with:
    """ruby
    require 'spec_helper'
    RSpec.describe "foo" do
      it "returns baz" do
        expect("foo").to eq("baz")
      end
    end
    """
    When I run `rspec`
    Then the output should contain "1 example, 1 failure"
    And the output should contain "lib/rspec/expectations"

  Scenario: Appending to `backtrace_exclusion_patterns`
    Given a file named "spec/support/assert_baz.rb" with:
    """ruby
    require "support/really_assert_baz"

    def assert_baz(arg)
      really_assert_baz(arg)
    end
    """
    And a file named "spec/support/really_assert_baz.rb" with:
    """ruby
    def really_assert_baz(arg)
      expect(arg).to eq("baz")
    end
    """
    And a file named "spec/example_spec.rb" with:
    """ruby
    require "support/assert_baz"
    RSpec.configure do |config|
      config.backtrace_exclusion_patterns << /really/
    end

    RSpec.describe "bar" do
      it "is baz" do
        assert_baz("bar")
      end
    end
    """
    When I run `rspec`
    Then the output should contain "1 example, 1 failure"
    And the output should contain "assert_baz"
    But the output should not contain "really_assert_baz"
    And the output should not contain "lib/rspec/expectations"

  Scenario: Running `rspec` with `--backtrace` prints unfiltered backtraces
    Given a file named "spec/support/custom_helper.rb" with:
    """ruby
    def assert_baz(arg)
      expect(arg).to eq("baz")
    end
    """
    And a file named "spec/example_spec.rb" with:
    """ruby
    require "support/custom_helper"

    RSpec.configure do |config|
      config.backtrace_exclusion_patterns << /custom_helper/
    end

    RSpec.describe "bar" do
      it "is baz" do
        assert_baz("bar")
      end
    end
    """
    When I run `rspec --backtrace`
    Then the output should contain "1 example, 1 failure"
    And the output should contain "spec/support/custom_helper.rb:2:in `assert_baz'"
    And the output should contain "lib/rspec/expectations"
    And the output should contain "lib/rspec/core"

  Scenario: Using `filter_gems_from_backtrace` to filter the named gem
    Given a vendored gem named "my_gem" containing a file named "lib/my_gem.rb" with:
      """ruby
      class MyGem
        def self.do_amazing_things!
          # intentional bug to trigger an exception
          impossible_math = 10 / 0
          "10 div 0 is: #{impossible_math}"
        end
      end
      """
    And a file named "spec/use_my_gem_spec.rb" with:
      """ruby
      require 'my_gem'

      RSpec.describe "Using my_gem" do
        it 'does amazing things' do
          expect(MyGem.do_amazing_things!).to include("10 div 0 is")
        end
      end
      """
    And a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |config|
        config.filter_gems_from_backtrace "my_gem"
      end
      """
    Then the output from `rspec` should contain "vendor/my_gem-1.2.3/lib/my_gem.rb:4:in `do_amazing_things!'"
    But the output from `rspec --require spec_helper` should not contain "vendor/my_gem-1.2.3/lib/my_gem.rb:4:in `do_amazing_things!'"
