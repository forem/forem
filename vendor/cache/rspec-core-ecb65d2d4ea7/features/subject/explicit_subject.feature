Feature: Explicit Subject

  Use `subject` in the group scope to explicitly define the value that is returned by the
  `subject` method in the example scope.

  Note that while the examples below demonstrate how the `subject` helper can be used
  as a user-facing concept, we recommend that you reserve it for support of custom
  matchers and/or extension libraries that hide its use from examples.

  A named `subject` improves on the explicit `subject` by assigning it a contextually
  semantic name. Since a named `subject` is an explicit `subject`, it still defines the value
  that is returned by the `subject` method in the example scope. However, it defines an
  additional helper method with the provided name. This helper method is memoized.
  The value is cached across multiple calls in the same example but not across examples.

  We recommend using the named helper method over `subject` in examples.

  For more information about declaring a `subject` see the [API docs](http://rubydoc.info/github/rspec/rspec-core/RSpec/Core/MemoizedHelpers/ClassMethods#subject-instance_method).

  Scenario: A `subject` can be defined and used in the top level group scope
    Given a file named "top_level_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some elements" do
        subject { [1, 2, 3] }

        it "has the prescribed elements" do
          expect(subject).to eq([1, 2, 3])
        end
      end
      """
    When I run `rspec top_level_subject_spec.rb`
    Then the examples should all pass

  Scenario: The `subject` defined in an outer group is available to inner groups
    Given a file named "nested_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        subject { [1, 2, 3] }

        describe "has some elements" do
          it "which are the prescribed elements" do
            expect(subject).to eq([1, 2, 3])
          end
        end
      end
      """
    When I run `rspec nested_subject_spec.rb`
    Then the examples should all pass

  Scenario: The `subject` is memoized within an example but not across examples
    **Note:** This scenario shows mutation being performed in a `subject` definition block. This
    behavior is generally discouraged as it makes it more difficult to understand the specs.
    This is technique is used simply as a tool to demonstrate how the memoization occurs.
    Given a file named "memoized_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        # This uses a context local variable. As you can see from the
        # specs, it can mutate across examples. Use with caution.
        element_list = [1, 2, 3]

        subject { element_list.pop }

        it "is memoized across calls (i.e. the block is invoked once)" do
          expect {
            3.times { subject }
          }.to change{ element_list }.from([1, 2, 3]).to([1, 2])
          expect(subject).to eq(3)
        end

        it "is not memoized across examples" do
          expect{ subject }.to change{ element_list }.from([1, 2]).to([1])
          expect(subject).to eq(2)
        end
      end
      """
    When I run `rspec memoized_subject_spec.rb`
    Then the examples should all pass

  Scenario: The `subject` is available in `before` hooks
    Given a file named "before_hook_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some elements" do
        subject { [] }

        before { subject.push(1, 2, 3) }

        it "has the prescribed elements" do
          expect(subject).to eq([1, 2, 3])
        end
      end
      """
    When I run `rspec before_hook_subject_spec.rb`
    Then the examples should all pass

  Scenario: Helper methods can be invoked from a `subject` definition block
    Given a file named "helper_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some elements" do
        def prepared_array
          [1, 2, 3]
        end

        subject { prepared_array }

        it "has the prescribed elements" do
          expect(subject).to eq([1, 2, 3])
        end
      end
      """
    When I run `rspec helper_subject_spec.rb`
    Then the examples should all pass

  Scenario: Use the `subject!` bang method to call the definition block before the example
    Given a file named "subject_bang_spec.rb" with:
      """ruby
      RSpec.describe "eager loading with subject!" do
        subject! { element_list.push(99) }

        let(:element_list) { [1, 2, 3] }

        it "calls the definition block before the example" do
          element_list.push(5)
          expect(element_list).to eq([1, 2, 3, 99, 5])
        end
      end
      """
    When I run `rspec subject_bang_spec.rb`
    Then the examples should all pass

  Scenario: Use `subject(:name)` to define a memoized helper method
    **Note:** While a global variable is used in the examples below, this behavior is strongly
    discouraged in actual specs. It is used here simply to demonstrate the value will be
    cached across multiple calls in the same example but not across examples.
    Given a file named "named_subject_spec.rb" with:
      """ruby
      $count = 0

      RSpec.describe "named subject" do
        subject(:global_count) { $count += 1 }

        it "is memoized across calls (i.e. the block is invoked once)" do
          expect {
            2.times { global_count }
          }.not_to change{ global_count }.from(1)
        end

        it "is not cached across examples" do
          expect(global_count).to eq(2)
        end

        it "is still available using the subject method" do
          expect(subject).to eq(3)
        end

        it "works with the one-liner syntax" do
          is_expected.to eq(4)
        end

        it "the subject and named helpers return the same object" do
          expect(global_count).to be(subject)
        end

        it "is set to the block return value (i.e. the global $count)" do
          expect(global_count).to be($count)
        end
      end
      """
    When I run `rspec named_subject_spec.rb`
    Then the examples should all pass

  Scenario: Use `subject!(:name)` to define a helper method called before the example
    Given a file named "named_subject_bang_spec.rb" with:
      """ruby
      RSpec.describe "eager loading using a named subject!" do
        subject!(:updated_list) { element_list.push(99) }

        let(:element_list) { [1, 2, 3] }

        it "calls the definition block before the example" do
          element_list.push(5)
          expect(element_list).to eq([1, 2, 3, 99, 5])
          expect(updated_list).to be(element_list)
        end
      end
      """
    When I run `rspec named_subject_bang_spec.rb`
    Then the examples should all pass
