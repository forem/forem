Feature: shared examples

  Shared examples let you describe behaviour of classes or modules. When declared,
  a shared group's content is stored. It is only realized in the context of
  another example group, which provides any context the shared group needs to
  run.

  A shared group is included in another group using any of:

  ```ruby
  include_examples "name"      # include the examples in the current context
  it_behaves_like "name"       # include the examples in a nested context
  it_should_behave_like "name" # include the examples in a nested context
  matching metadata            # include the examples in the current context
  ```

  **WARNING:** Files containing shared groups must be loaded before the files that
  use them.  While there are conventions to handle this, RSpec does _not_ do
  anything special (like autoload). Doing so would require a strict naming
  convention for files that would break existing suites.

  **WARNING:** When you include parameterized examples in the current context multiple
  times, you may override previous method definitions and last declaration wins.
  So if you have this kind of shared example (or shared context)

  ```ruby
  RSpec.shared_examples "some example" do |parameter|
    \# Same behavior is triggered also with either `def something; 'some value'; end`
    \# or `define_method(:something) { 'some value' }`
    let(:something) { parameter }
    it "uses the given parameter" do
      expect(something).to eq(parameter)
    end
  end

  RSpec.describe SomeClass do
    include_examples "some example", "parameter1"
    include_examples "some example", "parameter2"
  end
  ```

  You're actually doing this (notice that first example will fail):

  ```ruby
  RSpec.describe SomeClass do
    \# Reordered code for better understanding of what is happening
    let(:something) { "parameter1" }
    let(:something) { "parameter2" }

    it "uses the given parameter" do
      \# This example will fail because last let "wins"
      expect(something).to eq("parameter1")
    end

    it "uses the given parameter" do
      expect(something).to eq("parameter2")
    end
  end
  ```

  To prevent this kind of subtle error a warning is emitted if you declare multiple
  methods with the same name in the same context. Should you get this warning
  the simplest solution is to replace `include_examples` with `it_behaves_like`, in this
  way method overriding is avoided because of the nested context created by `it_behaves_like`

  Conventions:
  ------------

  1.  The simplest approach is to require files with shared examples explicitly
      from the files that use them. Keep in mind that RSpec adds the `spec`
      directory to the `LOAD_PATH`, so you can say `require
      'shared_examples_for_widgets'` to require a file at
      `#{PROJECT_ROOT}/spec/shared_examples_for_widgets.rb`.

  2.  One convention is to put files containing shared examples in `spec/support/`
      and require files in that directory from `spec/spec_helper.rb`:

      ```ruby
      Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
      ```

      Historically, this was included in the generated `spec/spec_helper.rb` file in
      `rspec-rails`. However, in order to keep your test suite boot time down,
      it's a good idea to not autorequire all files in a directory like this.
      When running only one spec file, loading unneeded dependencies or performing
      unneeded setup can have a significant, noticable effect on how long it takes
      before the first example runs.

  3. When all of the groups that include the shared group reside in the same file,
     just declare the shared group in that file.

  Scenario: Shared examples group included in two groups in one file
    Given a file named "collection_spec.rb" with:
      """ruby
      require "set"

      RSpec.shared_examples "a collection" do
        let(:collection) { described_class.new([7, 2, 4]) }

        context "initialized with 3 items" do
          it "says it has three items" do
            expect(collection.size).to eq(3)
          end
        end

        describe "#include?" do
          context "with an item that is in the collection" do
            it "returns true" do
              expect(collection.include?(7)).to be(true)
            end
          end

          context "with an item that is not in the collection" do
            it "returns false" do
              expect(collection.include?(9)).to be(false)
            end
          end
        end
      end

      RSpec.describe Array do
        it_behaves_like "a collection"
      end

      RSpec.describe Set do
        it_behaves_like "a collection"
      end
      """
    When I run `rspec collection_spec.rb --format documentation`
    Then the examples should all pass
    And the output should contain:
      """
      Array
        behaves like a collection
          initialized with 3 items
            says it has three items
          #include?
            with an item that is in the collection
              returns true
            with an item that is not in the collection
              returns false

      Set
        behaves like a collection
          initialized with 3 items
            says it has three items
          #include?
            with an item that is in the collection
              returns true
            with an item that is not in the collection
              returns false
      """

  Scenario: Providing context to a shared group using a block
    Given a file named "shared_example_group_spec.rb" with:
    """ruby
    require "set"

    RSpec.shared_examples "a collection object" do
      describe "<<" do
        it "adds objects to the end of the collection" do
          collection << 1
          collection << 2
          expect(collection.to_a).to match_array([1, 2])
        end
      end
    end

    RSpec.describe Array do
      it_behaves_like "a collection object" do
        let(:collection) { Array.new }
      end
    end

    RSpec.describe Set do
      it_behaves_like "a collection object" do
        let(:collection) { Set.new }
      end
    end
    """
    When I run `rspec shared_example_group_spec.rb --format documentation`
    Then the examples should all pass
    And the output should contain:
      """
      Array
        behaves like a collection object
          <<
            adds objects to the end of the collection

      Set
        behaves like a collection object
          <<
            adds objects to the end of the collection
      """

  Scenario: Passing parameters to a shared example group
    Given a file named "shared_example_group_params_spec.rb" with:
    """ruby
    RSpec.shared_examples "a measurable object" do |measurement, measurement_methods|
      measurement_methods.each do |measurement_method|
        it "should return #{measurement} from ##{measurement_method}" do
          expect(subject.send(measurement_method)).to eq(measurement)
        end
      end
    end

    RSpec.describe Array, "with 3 items" do
      subject { [1, 2, 3] }
      it_should_behave_like "a measurable object", 3, [:size, :length]
    end

    RSpec.describe String, "of 6 characters" do
      subject { "FooBar" }
      it_should_behave_like "a measurable object", 6, [:size, :length]
    end
    """
    When I run `rspec shared_example_group_params_spec.rb --format documentation`
    Then the examples should all pass
    And the output should contain:
      """
      Array with 3 items
        it should behave like a measurable object
          should return 3 from #size
          should return 3 from #length

      String of 6 characters
        it should behave like a measurable object
          should return 6 from #size
          should return 6 from #length
      """

  Scenario: Aliasing `it_should_behave_like` to `it_has_behavior`
    Given a file named "shared_example_group_spec.rb" with:
      """ruby
      RSpec.configure do |c|
        c.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
      end

      RSpec.shared_examples 'sortability' do
        it 'responds to <=>' do
          expect(sortable).to respond_to(:<=>)
        end
      end

      RSpec.describe String do
        it_has_behavior 'sortability' do
          let(:sortable) { 'sample string' }
        end
      end
      """
    When I run `rspec shared_example_group_spec.rb --format documentation`
    Then the examples should all pass
    And the output should contain:
      """
      String
        has behavior: sortability
          responds to <=>
      """

  Scenario: Sharing metadata automatically includes shared example groups
    Given a file named "shared_example_metadata_spec.rb" with:
      """ruby
      RSpec.shared_examples "shared stuff", :a => :b do
        it 'runs wherever the metadata is shared' do
        end
      end

      RSpec.describe String, :a => :b do
      end
      """
    When I run `rspec shared_example_metadata_spec.rb`
    Then the output should contain:
      """
      1 example, 0 failures
      """

  Scenario: Shared examples are nestable by context
    Given a file named "context_specific_examples_spec.rb" with:
      """Ruby
      RSpec.describe "shared examples" do
        context "per context" do

          shared_examples "shared examples are nestable" do
            specify { expect(true).to eq true }
          end

          it_behaves_like "shared examples are nestable"
        end
      end
      """
    When I run `rspec context_specific_examples_spec.rb`
    Then the output should contain:
      """
      1 example, 0 failures
      """

  Scenario: Shared examples are accessible from offspring contexts
    Given a file named "context_specific_examples_spec.rb" with:
      """Ruby
      RSpec.describe "shared examples" do
        shared_examples "shared examples are nestable" do
          specify { expect(true).to eq true }
        end

        context "per context" do
          it_behaves_like "shared examples are nestable"
        end
      end
      """
    When I run `rspec context_specific_examples_spec.rb`
    Then the output should contain:
      """
      1 example, 0 failures
      """
    And the output should not contain:
      """
      Accessing shared_examples defined across contexts is deprecated
      """

  Scenario: Shared examples are isolated per context
    Given a file named "isolated_shared_examples_spec.rb" with:
      """Ruby
      RSpec.describe "shared examples" do
        context do
          shared_examples "shared examples are isolated" do
            specify { expect(true).to eq true }
          end
        end

        context do
          it_behaves_like "shared examples are isolated"
        end
      end
      """
    When I run `rspec isolated_shared_examples_spec.rb`
    Then the output should contain:
      """
      Could not find shared examples \"shared examples are isolated\"
      """
