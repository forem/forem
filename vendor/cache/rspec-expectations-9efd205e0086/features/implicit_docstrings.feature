Feature: implicit docstrings

  When you use rspec-expectations with rspec-core, RSpec is able to auto-generate the
  docstrings for examples for you based on the last expectation in the example. This can be
  handy when the matcher expresses exactly what you would write in your example docstring,
  but it can also be easily abused. We find that the freeform nature of the docstring provides
  a lot of value when used well (e.g. to document the "why" of a particular behavior), and you
  lose that kind of flexibility when you rely on the matcher to generate the docstring for you.

  In general, we recommend only using this feature when the matcher aligns _exactly_ with the
  docstring you would write. Even then, many users prefer the explicitness of the full
  docstring, so use this feature with care (if at all).

  Scenario: run passing examples
    Given a file named "implicit_docstrings_spec.rb" with:
    """ruby
    RSpec.describe "Examples with no docstrings generate their own:" do
      specify { expect(3).to be < 5 }
      specify { expect([1,2,3]).to include(2) }
      specify { expect([1,2,3]).to respond_to(:size) }
    end
    """

    When I run `rspec ./implicit_docstrings_spec.rb -fdoc`

    Then the output should contain "is expected to be < 5"
    And the output should contain "is expected to include 2"
    And the output should contain "is expected to respond to #size"

  Scenario: run failing examples
    Given a file named "failing_implicit_docstrings_spec.rb" with:
    """ruby
    RSpec.describe "Failing examples with no descriptions" do
      # description is auto-generated per the last executed expectation
      specify do
        expect(3).to equal(2)
        expect(5).to equal(5)
      end

      specify { expect(3).to be > 5 }
      specify { expect([1,2,3]).to include(4) }
      specify { expect([1,2,3]).not_to respond_to(:size) }
    end
    """

    When I run `rspec ./failing_implicit_docstrings_spec.rb -fdoc`

    Then the output should contain "is expected to equal 2"
    And the output should contain "is expected to be > 5"
    And the output should contain "is expected to include 4"
    And the output should contain "is expected not to respond to #size"
