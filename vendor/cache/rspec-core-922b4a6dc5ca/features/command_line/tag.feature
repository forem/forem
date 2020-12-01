Feature: `--tag` option

  Use the `--tag` (or `-t`) option to run examples that match a specified tag.
  The tag can be a simple `name` or a `name:value` pair.

  If a simple `name` is supplied, only examples with `:name => true` will run.
  If a `name:value` pair is given, examples with `name => value` will run,
  where `value` is always a string. In both cases, `name` is converted to a symbol.

  Tags can also be used to exclude examples by adding a `~` before the tag. For
  example, `~tag` will exclude all examples marked with `:tag => true` and
  `~tag:value` will exclude all examples marked with `:tag => value`.

  Filtering by tag uses a hash internally, which means that you can't specify
  multiple filters for the same key. For instance, if you try to exclude
  `:name => 'foo'` and `:name => 'bar'`, you will only end up excluding
  `:name => 'bar'`.

  To be compatible with the Cucumber syntax, tags can optionally start with an
  `@` symbol, which will be ignored as part of the tag, e.g. `--tag @focus` is
  treated the same as `--tag focus` and is expanded to `:focus => true`.

  Background:
    Given a file named "tagged_spec.rb" with:
      """ruby
      RSpec.describe "group with tagged specs" do
        it "example I'm working now", :focus => true do; end
        it "special example with string", :type => 'special' do; end
        it "special example with symbol", :type => :special do; end
        it "slow example", :skip => true do; end
        it "ordinary example", :speed => 'slow' do; end
        it "untagged example" do; end
      end
      """

  Scenario: Filter examples with non-existent tag
    When I run `rspec . --tag mytag`
    Then the process should succeed even though no examples were run

  Scenario: Filter examples with a simple tag
    When I run `rspec . --tag focus`
    Then the output should contain "include {:focus=>true}"
    And the examples should all pass

  Scenario: Filter examples with a simple tag and @
    When I run `rspec . --tag @focus`
    Then the output should contain "include {:focus=>true}"
    Then the examples should all pass

  Scenario: Filter examples with a `name:value` tag
    When I run `rspec . --tag type:special`
    Then the output should contain:
      """
      include {:type=>"special"}
      """
    And the output should contain "2 examples"
    And the examples should all pass

  Scenario: Filter examples with a `name:value` tag and @
    When I run `rspec . --tag @type:special`
    Then the output should contain:
      """
      include {:type=>"special"}
      """
    And the examples should all pass

  Scenario: Exclude examples with a simple tag
    When I run `rspec . --tag ~skip`
    Then the output should contain "exclude {:skip=>true}"
    Then the examples should all pass

  Scenario: Exclude examples with a simple tag and @
    When I run `rspec . --tag ~@skip`
    Then the output should contain "exclude {:skip=>true}"
    Then the examples should all pass

  Scenario: Exclude examples with a `name:value` tag
    When I run `rspec . --tag ~speed:slow`
    Then the output should contain:
      """
      exclude {:speed=>"slow"}
      """
    Then the examples should all pass

  Scenario: Exclude examples with a `name:value` tag and @
    When I run `rspec . --tag ~@speed:slow`
    Then the output should contain:
      """
      exclude {:speed=>"slow"}
      """
    Then the examples should all pass

  Scenario: Filter examples with a simple tag, exclude examples with another tag
    When I run `rspec . --tag focus --tag ~skip`
    Then the output should contain "include {:focus=>true}"
    And the output should contain "exclude {:skip=>true}"
    And the examples should all pass

  Scenario: Exclude examples with multiple tags
    When I run `rspec . --tag ~skip --tag ~speed:slow`
    Then the output should contain one of the following:
      | exclude {:skip=>true, :speed=>"slow"} |
      | exclude {:speed=>"slow", :skip=>true} |
    Then the examples should all pass
