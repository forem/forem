Feature: filters

  `before`, `after`, and `around` hooks defined in the block passed to
  `RSpec.configure` can be constrained to specific examples and/or groups using
  metadata as a filter.

  ```ruby
  RSpec.configure do |c|
    c.before(:example, :type => :model) do
    end
  end

  RSpec.describe "something", :type => :model do
  end
  ```

  Note that filtered `:context` hooks will still be applied to individual examples with matching metadata -- in effect, every example has a singleton example group containing just the one example (analogous to Ruby's singleton classes).

  You can also specify metadata using only symbols.

  Scenario: Filter `before(:example)` hooks using arbitrary metadata
    Given a file named "filter_before_example_hooks_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:example, :foo => :bar) do
          invoked_hooks << :before_example_foo_bar
        end
      end

      RSpec.describe "a filtered before :example hook" do
        let(:invoked_hooks) { [] }

        describe "group without matching metadata" do
          it "does not run the hook" do
            expect(invoked_hooks).to be_empty
          end

          it "runs the hook for an example with matching metadata", :foo => :bar do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end

        describe "group with matching metadata", :foo => :bar do
          it "runs the hook" do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end
      end
      """
    When I run `rspec filter_before_example_hooks_spec.rb`
    Then the examples should all pass

  Scenario: Filter `after(:example)` hooks using arbitrary metadata
    Given a file named "filter_after_example_hooks_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.after(:example, :foo => :bar) do
          raise "boom!"
        end
      end

      RSpec.describe "a filtered after :example hook" do
        describe "group without matching metadata" do
          it "does not run the hook" do
            # should pass
          end

          it "runs the hook for an example with matching metadata", :foo => :bar do
            # should fail
          end
        end

        describe "group with matching metadata", :foo => :bar do
          it "runs the hook" do
            # should fail
          end
        end
      end
      """
    When I run `rspec filter_after_example_hooks_spec.rb`
    Then the output should contain "3 examples, 2 failures"

  Scenario: Filter `around(:example)` hooks using arbitrary metadata
    Given a file named "filter_around_example_hooks_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.around(:example, :foo => :bar) do |example|
          order << :before_around_example_foo_bar
          example.run
          expect(order).to eq([:before_around_example_foo_bar, :example])
        end
      end

      RSpec.describe "a filtered around(:example) hook" do
        let(:order) { [] }

        describe "a group without matching metadata" do
          it "does not run the hook" do
            expect(order).to be_empty
          end

          it "runs the hook for an example with matching metadata", :foo => :bar do
            expect(order).to eq([:before_around_example_foo_bar])
            order << :example
          end
        end

        describe "a group with matching metadata", :foo => :bar do
          it "runs the hook for an example with matching metadata", :foo => :bar do
            expect(order).to eq([:before_around_example_foo_bar])
            order << :example
          end
        end
      end
      """
    When I run `rspec filter_around_example_hooks_spec.rb`
    Then the examples should all pass

  Scenario: Filter `before(:context)` hooks using arbitrary metadata
    Given a file named "filter_before_context_hooks_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:context, :foo => :bar) { @hook = :before_context_foo_bar }
      end

      RSpec.describe "a filtered before(:context) hook" do
        describe "a group without matching metadata" do
          it "does not run the hook" do
            expect(@hook).to be_nil
          end

          it "runs the hook for a single example with matching metadata", :foo => :bar do
            expect(@hook).to eq(:before_context_foo_bar)
          end

          describe "a nested subgroup with matching metadata", :foo => :bar do
            it "runs the hook" do
              expect(@hook).to eq(:before_context_foo_bar)
            end
          end
        end

        describe "a group with matching metadata", :foo => :bar do
          it "runs the hook" do
            expect(@hook).to eq(:before_context_foo_bar)
          end

          describe "a nested subgroup" do
            it "runs the hook" do
              expect(@hook).to eq(:before_context_foo_bar)
            end
          end
        end
      end
      """
    When I run `rspec filter_before_context_hooks_spec.rb`
    Then the examples should all pass

  Scenario: Filter `after(:context)` hooks using arbitrary metadata
    Given a file named "filter_after_context_hooks_spec.rb" with:
      """ruby
      example_msgs = []

      RSpec.configure do |config|
        config.after(:context, :foo => :bar) do
          puts "after :context"
        end
      end

      RSpec.describe "a filtered after(:context) hook" do
        describe "a group without matching metadata" do
          it "does not run the hook" do
            puts "unfiltered"
          end

          it "runs the hook for a single example with matching metadata", :foo => :bar do
            puts "filtered 1"
          end
        end

        describe "a group with matching metadata", :foo => :bar do
          it "runs the hook" do
            puts "filtered 2"
          end
        end

        describe "another group without matching metadata" do
          describe "a nested subgroup with matching metadata", :foo => :bar do
            it "runs the hook" do
              puts "filtered 3"
            end
          end
        end
      end
      """
    When I run `rspec --format progress filter_after_context_hooks_spec.rb --order defined`
    Then the examples should all pass
    And the output should contain:
      """
      unfiltered
      .filtered 1
      after :context
      .filtered 2
      .after :context
      filtered 3
      .after :context
      """

  Scenario: Use symbols as metadata
    Given a file named "less_verbose_metadata_filter.rb" with:
      """ruby
      RSpec.configure do |c|
        c.before(:example, :before_example) { puts "before example" }
        c.after(:example,  :after_example) { puts "after example" }
        c.around(:example, :around_example) do |example|
          puts "around example (before)"
          example.run
          puts "around example (after)"
        end
        c.before(:context, :before_context) { puts "before context" }
        c.after(:context,  :after_context) { puts "after context" }
      end

      RSpec.describe "group 1", :before_context, :after_context do
        it("") { puts "example 1" }
        it("", :before_example) { puts "example 2" }
        it("", :after_example) { puts "example 3" }
        it("", :around_example) { puts "example 4" }
      end
      """
    When I run `rspec --format progress less_verbose_metadata_filter.rb`
    Then the examples should all pass
    And the output should contain:
      """
      before context
      example 1
      .before example
      example 2
      .example 3
      after example
      .around example (before)
      example 4
      around example (after)
      .after context
      """

  Scenario: Filtering hooks using symbols
    Given a file named "filter_example_hooks_with_symbol_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:example, :foo) do
          invoked_hooks << :before_example_foo_bar
        end
      end

      RSpec.describe "a filtered before :example hook" do
        let(:invoked_hooks) { [] }

        describe "group without a matching metadata key" do
          it "does not run the hook" do
            expect(invoked_hooks).to be_empty
          end

          it "does not run the hook for an example with metadata hash containing the key with a falsey value", :foo => nil do
            expect(invoked_hooks).to be_empty
          end

          it "runs the hook for an example with metadata hash containing the key with a truthy value", :foo => :bar do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end

          it "runs the hook for an example with only the key defined", :foo do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end

        describe "group with matching metadata key", :foo do
          it "runs the hook" do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end
      end
      """
    When I run `rspec filter_example_hooks_with_symbol_spec.rb`
    Then the examples should all pass

  Scenario: Filtering hooks using a hash
    Given a file named "filter_example_hooks_with_hash_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:example, :foo => { :bar => :baz, :slow => true }) do
          invoked_hooks << :before_example_foo_bar
        end
      end

      RSpec.describe "a filtered before :example hook" do
        let(:invoked_hooks) { [] }

        describe "group without matching metadata" do
          it "does not run the hook" do
            expect(invoked_hooks).to be_empty
          end

          it "does not run the hook for an example if only part of the filter matches", :foo => { :bar => :baz } do
            expect(invoked_hooks).to be_empty
          end

          it "runs the hook for an example if the metadata contains all key value pairs from the filter", :foo => { :bar => :baz, :slow => true, :extra => :pair } do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end

        describe "group with matching metadata", :foo => { :bar => :baz, :slow => true } do
          it "runs the hook" do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end
      end
      """
    When I run `rspec filter_example_hooks_with_hash_spec.rb`
    Then the examples should all pass

  Scenario: Filtering hooks using a Proc
    Given a file named "filter_example_hooks_with_proc_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:example, :foo => Proc.new { |value| value.is_a?(String) } ) do
          invoked_hooks << :before_example_foo_bar
        end
      end

      RSpec.describe "a filtered before :example hook" do
        let(:invoked_hooks) { [] }

        describe "group without matching metadata" do
          it "does not run the hook" do
            expect(invoked_hooks).to be_empty
          end

          it "does not run the hook if the proc returns false", :foo => :bar do
            expect(invoked_hooks).to be_empty
          end

          it "runs the hook if the proc returns true", :foo => 'bar' do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end

        describe "group with matching metadata", :foo => 'bar' do
          it "runs the hook" do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end
      end
      """
    When I run `rspec filter_example_hooks_with_proc_spec.rb`
    Then the examples should all pass

  Scenario: Filtering hooks using a regular expression
    Given a file named "filter_example_hooks_with_regexp_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:example, :foo => /bar/ ) do
          invoked_hooks << :before_example_foo_bar
        end
      end

      RSpec.describe "a filtered before :example hook" do
        let(:invoked_hooks) { [] }

        describe "group without matching metadata" do
          it "does not run the hook" do
            expect(invoked_hooks).to be_empty
          end

          it "does not run the hook if the value does not match", :foo => 'baz' do
            expect(invoked_hooks).to be_empty
          end

          it "runs the hook if the value matches", :foo => 'bar' do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end

        describe "group with matching metadata", :foo => 'bar' do
          it "runs the hook" do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end
      end
      """
    When I run `rspec filter_example_hooks_with_regexp_spec.rb`
    Then the examples should all pass

  Scenario: Filtering hooks using string comparison
    Given a file named "filter_example_hooks_with_strcmp_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.before(:example, :foo => :bar ) do
          invoked_hooks << :before_example_foo_bar
        end
      end

      RSpec.describe "a filtered before :example hook" do
        let(:invoked_hooks) { [] }

        describe "group without matching metadata" do
          it "does not run the hook" do
            expect(invoked_hooks).to be_empty
          end

          it "does not run the hook if the coerced values do not match", :foo => 'baz' do
            expect(invoked_hooks).to be_empty
          end

          it "runs the hook if the coerced values match", :foo => 'bar' do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end

        describe "group with matching metadata", :foo => 'bar' do
          it "runs the hook" do
            expect(invoked_hooks).to eq([:before_example_foo_bar])
          end
        end
      end
      """
    When I run `rspec filter_example_hooks_with_strcmp_spec.rb`
    Then the examples should all pass
