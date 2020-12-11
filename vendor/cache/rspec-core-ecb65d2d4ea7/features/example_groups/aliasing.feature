Feature: aliasing

  `describe` and `context` are the default aliases for `example_group`. You can
  define your own aliases for `example_group` and give those custom aliases
  default metadata.

  RSpec provides a few built-in aliases:

    * `xdescribe` and `xcontext` add `:skip` metadata to the example group in
      order to temporarily disable the examples.
    * `fdescribe` and `fcontext` add `:focus` metadata to the example group in
      order to make it easy to temporarily focus the example group (when
      combined with `config.filter_run :focus`.)

  Scenario: Custom example group aliases with metadata
    Given a file named "nested_example_group_aliases_spec.rb" with:
    """ruby
    RSpec.configure do |c|
      c.alias_example_group_to :detail, :detailed => true
    end

    RSpec.detail "a detail" do
      it "can do some less important stuff" do
      end
    end

    RSpec.describe "a thing" do
      describe "in broad strokes" do
        it "can do things" do
        end
      end

      detail "something less important" do
        it "can do an unimportant thing" do
        end
      end
    end
    """
    When I run `rspec nested_example_group_aliases_spec.rb --tag detailed -fdoc`
    Then the output should contain:
      """
      a detail
        can do some less important stuff

      a thing
        something less important
      """

