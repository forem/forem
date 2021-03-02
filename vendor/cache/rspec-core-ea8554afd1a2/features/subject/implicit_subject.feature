Feature: implicitly defined subject

  If the first argument to an example group is a class, an instance of that
  class is exposed to each example in that example group via the `subject`
  method.

  While the examples below demonstrate how `subject` can be used as a
  user-facing concept, we recommend that you reserve it for support of custom
  matchers and/or extension libraries that hide its use from examples.

  Scenario: `subject` exposed in top level group
    Given a file named "top_level_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        it "should be empty when first created" do
          expect(subject).to be_empty
        end
      end
      """
    When I run `rspec ./top_level_subject_spec.rb`
    Then the examples should all pass

  Scenario: `subject` in a nested group
    Given a file named "nested_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe "when first created" do
          it "should be empty" do
            expect(subject).to be_empty
          end
        end
      end
      """
    When I run `rspec nested_subject_spec.rb`
    Then the examples should all pass

  Scenario: `subject` in a nested group with a different class (innermost wins)
    Given a file named "nested_subject_spec.rb" with:
      """ruby
      class ArrayWithOneElement < Array
        def initialize(*)
          super
          unshift "first element"
        end
      end

      RSpec.describe Array do
        describe ArrayWithOneElement do
          context "referenced as subject" do
            it "contains one element" do
              expect(subject).to include("first element")
            end
          end
        end
      end
      """
    When I run `rspec nested_subject_spec.rb`
    Then the examples should all pass
