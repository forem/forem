@oneliner-should
Feature: One-liner syntax

  RSpec supports a one-liner syntax for setting an expectation on the
  `subject`.  RSpec will give the examples a doc string that is auto-
  generated from the matcher used in the example. This is designed specifically
  to help avoid duplication in situations where the doc string and the matcher
  used in the example mirror each other exactly. When used excessively, it can
  produce documentation output that does not read well or contribute to
  understanding the object you are describing.

  This comes in two flavors:

    * `is_expected` is defined simply as `expect(subject)` and is designed for
      when you are using rspec-expectations with its newer expect-based syntax.
    * `should` was designed back when rspec-expectations only had a should-based
      syntax. However, it continues to be available and work even if the
      `:should` syntax is disabled (since that merely removes `Object#should`
      but this is `RSpec::Core::ExampleGroup#should`).

  Notes:

    * This feature is only available when using rspec-expectations.
    * Examples defined using this one-liner syntax cannot be directly selected from the command line using the [`--example` option](../command-line/example-option).
    * The one-liner syntax only works with non-block expectations (e.g. `expect(obj).to eq`, etc) and it cannot be used with block expectations (e.g. `expect { object }`).

  Scenario: Implicit subject
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe "when first created" do
          # Rather than:
          # it "should be empty" do
          #   subject.should be_empty
          # end

          it { should be_empty }
          # or
          it { is_expected.to be_empty }
        end
      end
      """
    When I run `rspec example_spec.rb --format doc`
    Then the examples should all pass
     And the output should contain:
       """
       Array
         when first created
           is expected to be empty
           is expected to be empty
       """

  Scenario: Explicit subject
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe "with 3 items" do
          subject { [1,2,3] }
          it { should_not be_empty }
          # or
          it { is_expected.not_to be_empty }
        end
      end
      """
    When I run `rspec example_spec.rb --format doc`
    Then the examples should all pass
     And the output should contain:
       """
       Array
         with 3 items
           is expected not to be empty
           is expected not to be empty
       """
