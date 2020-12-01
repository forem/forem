Feature: shared context

  Use `shared_context` to define a block that will be evaluated in the context of example groups either locally, using `include_context` in an example group, or globally using `config.include_context`.

  When implicitly including shared contexts via matching metadata, the normal way is to define matching metadata on an example group, in which case the context is included in the entire group. However, you also have the option to include it in an individual example instead. RSpec treats every example as having a singleton example group (analogous to Ruby's singleton classes) containing just the one example.

  Background:
    Given a file named "shared_stuff.rb" with:
      """ruby
      RSpec.configure do |rspec|
        # This config option will be enabled by default on RSpec 4,
        # but for reasons of backwards compatibility, you have to
        # set it on RSpec 3.
        #
        # It causes the host group and examples to inherit metadata
        # from the shared context.
        rspec.shared_context_metadata_behavior = :apply_to_host_groups
      end

      RSpec.shared_context "shared stuff", :shared_context => :metadata do
        before { @some_var = :some_value }
        def shared_method
          "it works"
        end
        let(:shared_let) { {'arbitrary' => 'object'} }
        subject do
          'this is the subject'
        end
      end

      RSpec.configure do |rspec|
        rspec.include_context "shared stuff", :include_shared => true
      end
      """

  Scenario: Declare a shared context and include it with `include_context`
    Given a file named "shared_context_example.rb" with:
      """ruby
      require "./shared_stuff.rb"

      RSpec.describe "group that includes a shared context using 'include_context'" do
        include_context "shared stuff"

        it "has access to methods defined in shared context" do
          expect(shared_method).to eq("it works")
        end

        it "has access to methods defined with let in shared context" do
          expect(shared_let['arbitrary']).to eq('object')
        end

        it "runs the before hooks defined in the shared context" do
          expect(@some_var).to be(:some_value)
        end

        it "accesses the subject defined in the shared context" do
          expect(subject).to eq('this is the subject')
        end

        group = self

        it "inherits metadata from the included context" do |ex|
          expect(group.metadata).to include(:shared_context => :metadata)
          expect(ex.metadata).to include(:shared_context => :metadata)
        end
      end
      """
    When I run `rspec shared_context_example.rb`
    Then the examples should all pass

  Scenario: Declare a shared context, include it with `include_context` and extend it with an additional block
    Given a file named "shared_context_example.rb" with:
      """ruby
      require "./shared_stuff.rb"

      RSpec.describe "including shared context using 'include_context' and a block" do
        include_context "shared stuff" do
          let(:shared_let) { {'in_a' => 'block'} }
        end

        it "evaluates the block in the shared context" do
          expect(shared_let['in_a']).to eq('block')
        end
      end
      """
    When I run `rspec shared_context_example.rb`
    Then the examples should all pass

  Scenario: Declare a shared context and include it with metadata
    Given a file named "shared_context_example.rb" with:
      """ruby
      require "./shared_stuff.rb"

      RSpec.describe "group that includes a shared context using metadata", :include_shared => true do
        it "has access to methods defined in shared context" do
          expect(shared_method).to eq("it works")
        end

        it "has access to methods defined with let in shared context" do
          expect(shared_let['arbitrary']).to eq('object')
        end

        it "runs the before hooks defined in the shared context" do
          expect(@some_var).to be(:some_value)
        end

        it "accesses the subject defined in the shared context" do
          expect(subject).to eq('this is the subject')
        end

        group = self

        it "inherits metadata from the included context" do |ex|
          expect(group.metadata).to include(:shared_context => :metadata)
          expect(ex.metadata).to include(:shared_context => :metadata)
        end
      end
      """
    When I run `rspec shared_context_example.rb`
    Then the examples should all pass

  Scenario: Declare a shared context and include it with metadata of an individual example
    Given a file named "shared_context_example.rb" with:
      """ruby
      require "./shared_stuff.rb"

      RSpec.describe "group that does not include the shared context" do
        it "does not have access to shared methods normally" do
          expect(self).not_to respond_to(:shared_method)
        end

        it "has access to shared methods from examples with matching metadata", :include_shared => true do
          expect(shared_method).to eq("it works")
        end

        it "inherits metadata from the included context due to the matching metadata", :include_shared => true do |ex|
          expect(ex.metadata).to include(:shared_context => :metadata)
        end
      end
      """
    When I run `rspec shared_context_example.rb`
    Then the examples should all pass
