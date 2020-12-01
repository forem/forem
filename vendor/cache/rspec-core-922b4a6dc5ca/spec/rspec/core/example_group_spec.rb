# encoding: utf-8

module RSpec::Core
  RSpec.describe ExampleGroup do
    it_behaves_like "metadata hash builder" do
      def metadata_hash(*args)
        group = RSpec.describe('example description', *args)
        group.metadata
      end
    end

    %w[ expect double spy ].each do |method|
      context "when calling `#{method}`, an example API, on an example group" do
        it "tells the user they are in the wrong scope for that API" do
          expect {
            RSpec.describe { __send__(method, "foo") }
          }.to raise_error(ExampleGroup::WrongScopeError)
        end
      end
    end

    %w[ describe context let before it it_behaves_like ].each do |method|
      context "when calling `#{method}`, an example group API, from within an example" do
        it "tells the user they are in the wrong scope for that API" do
          ex = nil

          RSpec.describe do
            ex = example { __send__(method, "foo") }
          end.run

          expect(ex).to fail_with(ExampleGroup::WrongScopeError)
        end
      end
    end

    it "surfaces NameError from an example group for other missing APIs, like normal" do
      expect {
        RSpec.describe { foobar }
      }.to raise_error(NameError, /foobar/)
    end

    it "surfaces NameError from an example for other missing APIs, like normal" do
      ex = nil

      RSpec.describe do
        ex = example { foobar }
      end.run

      expect(ex).to fail_with(NameError)
    end

    context "when RSpec.configuration.format_docstrings is set to a block" do
      it "formats the description with that block" do
        RSpec.configuration.format_docstrings { |s| s.upcase }
        group = RSpec.describe(' an example ')
        expect(group.description).to eq(' AN EXAMPLE ')
      end
    end

    it 'does not treat the first argument as a metadata key even if it is a symbol' do
      group = RSpec.describe(:symbol)
      expect(group.metadata).not_to include(:symbol)
    end

    it 'treats the first argument as part of the description when it is a symbol' do
      group = RSpec.describe(:symbol)
      expect(group.description).to eq("symbol")
    end

    describe "constant naming" do
      around do |ex|
        before_constants = RSpec::ExampleGroups.constants
        ex.run
        after_constants = RSpec::ExampleGroups.constants

        (after_constants - before_constants).each do |name|
          RSpec::ExampleGroups.send(:remove_const, name)
        end
      end

      if RUBY_VERSION == "1.9.2"
        RSpec::Matchers.define :have_class_const do |class_name|
          match do |group|
            class_name.gsub!('::','_::')
            class_name << '_'
            group.name == "RSpec::ExampleGroups::#{class_name}" &&
            group == class_name.split('::').inject(RSpec::ExampleGroups) do |mod, name|
              mod.const_get(name)
            end
          end
        end
      else
        RSpec::Matchers.define :have_class_const do |class_name, _|
          match do |group|
            group.name == "RSpec::ExampleGroups::#{class_name}" &&
            group == class_name.split('::').inject(RSpec::ExampleGroups) do |mod, name|
              mod.const_get(name)
            end
          end
        end
      end

      it 'gives groups friendly human readable class names' do
        stub_const("MyGem::Klass", Class.new)
        parent = RSpec.describe(MyGem::Klass)
        expect(parent).to have_class_const("MyGemKlass")
      end

      it 'nests constants to match the group nesting' do
        grandparent = RSpec.describe("The grandparent")
        parent      = grandparent.describe("the parent")
        child       = parent.describe("the child")

        expect(parent).to have_class_const("TheGrandparent::TheParent")
        expect(child).to have_class_const("TheGrandparent::TheParent::TheChild")
      end

      it 'removes non-ascii characters from the const name since some rubies barf on that' do
        group = RSpec.describe("A chinese character: 们")
        expect(group).to have_class_const("AChineseCharacter")
      end

      it 'prefixes the const name with "Nested" if needed to make a valid const' do
        expect {
          ExampleGroup.const_set("1B", Object.new)
        }.to raise_error(NameError)

        group = RSpec.describe("1B")
        expect(group).to have_class_const("Nested1B")
      end

      it 'does not warn when defining a Config example group (since RbConfig triggers warnings when Config is referenced)' do
        expect { RSpec.describe("Config") }.not_to output.to_stderr
      end

      it 'ignores top level constants that have the same name' do
        parent = RSpec.describe("Some Parent Group")
        child  = parent.describe("Hash")
        # This would be `SomeParentGroup::Hash_2` if we didn't ignore the top level `Hash`
        expect(child).to have_class_const("SomeParentGroup::Hash")
      end

      it 'disambiguates name collisions by appending a number', :unless => RUBY_VERSION == '1.9.2' do
        groups = 10.times.map { RSpec.describe("Collision") }
        expect(groups[0]).to have_class_const("Collision")
        expect(groups[1]).to have_class_const("Collision_2")
        expect(groups[8]).to have_class_const("Collision_9")

        if RUBY_VERSION.to_f > 1.8 && !(defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx')
          # on 1.8.7, rbx "Collision_9".next => "Collisioo_0"
          expect(groups[9]).to have_class_const("Collision_10")
        end
      end

      it 'identifies unnamed groups as "Anonymous"' do
        # Wrap the anonymous group is a uniquely named one,
        # so the presence of another anonymous group in our
        # test suite doesn't cause an unexpected number
        # to be appended.
        group    = RSpec.describe("name of unnamed group")
        subgroup = group.describe
        expect(subgroup).to have_class_const("NameOfUnnamedGroup::Anonymous")
      end

      it 'assigns the const before evaling the group so error messages include the name' do
        expect {
          RSpec.describe("Calling an undefined method") { foo }
        }.to raise_error(/ExampleGroups::CallingAnUndefinedMethod/)
      end

      it "assigns the const before including shared contexts via metadata so error messages from eval'ing the context include the name" do
        RSpec.shared_context("foo", :foo) { bar }

        expect {
          RSpec.describe("Including shared context via metadata", :foo)
        }.to raise_error(NameError,
          a_string_including('ExampleGroups::IncludingSharedContextViaMetadata', 'bar')
        )
      end

      it 'does not have problems with example groups named "Core"', :unless => RUBY_VERSION == '1.9.2' do
        RSpec.describe("Core")
        expect(defined?(::RSpec::ExampleGroups::Core)).to be

        # The original bug was triggered when a group was defined AFTER one named `Core`,
        # due to it not using the fully qualified `::RSpec::Core::ExampleGroup` constant.
        group = RSpec.describe("Another group")
        expect(group).to have_class_const("AnotherGroup")
      end

      it 'does not have problems with example groups named "RSpec"', :unless => RUBY_VERSION == '1.9.2' do
        RSpec.describe("RSpec")
        expect(defined?(::RSpec::ExampleGroups::RSpec)).to be

        # The original bug was triggered when a group was defined AFTER one named `RSpec`,
        # due to it not using the fully qualified `::RSpec::Core::ExampleGroup` constant.
        group = RSpec.describe("Yet Another group")
        expect(group).to have_class_const("YetAnotherGroup")
      end
    end

    describe "ordering" do
      context "when tagged with `:order => :defined`" do
        it 'orders the subgroups and examples in defined order regardless of global order' do
          RSpec.configuration.order = :random

          run_order = []
          group = RSpec.describe "outer", :order => :defined do
            context "subgroup 1" do
              example { run_order << :g1_e1 }
              example { run_order << :g1_e2 }
            end

            context "subgroup 2" do
              example { run_order << :g2_e1 }
              example { run_order << :g2_e2 }
            end
          end

          group.run
          expect(run_order).to eq([:g1_e1, :g1_e2, :g2_e1, :g2_e2])
        end
      end

      context "when tagged with an unrecognized ordering" do
        let(:run_order) { [] }
        let(:definition_line) { __LINE__ + 4 }
        let(:group) do
          order = self.run_order

          RSpec.describe "group", :order => :unrecognized do
            example { order << :ex_1 }
            example { order << :ex_2 }
          end
        end

        before do
          RSpec.configuration.register_ordering(:global, &:reverse)
          allow(self.group).to receive(:warn)
        end

        it 'falls back to the global ordering' do
          self.group.run
          expect(self.run_order).to eq([:ex_2, :ex_1])
        end

        it 'prints a warning so users are notified of their mistake' do
          warning = nil
          allow(self.group).to receive(:warn) { |msg| warning = msg }

          self.group.run

          expect(warning).to match(/unrecognized/)
          expect(warning).to match(/#{File.basename __FILE__}:#{definition_line}/)
        end
      end

      context "when tagged with a custom ordering" do
        def ascending_numbers
          lambda { |g| Integer(g.description[/\d+/]) }
        end

        it 'uses the custom orderings' do
          RSpec.configure do |c|
            c.register_ordering :custom do |items|
              items.sort_by(&ascending_numbers)
            end
          end

          run_order = []
          group = RSpec.describe "outer", :order => :custom do
            example("e2") { run_order << :e2 }
            example("e1") { run_order << :e1 }

            context "subgroup 2" do
              example("ex 3") { run_order << :g2_e3 }
              example("ex 1") { run_order << :g2_e1 }
              example("ex 2") { run_order << :g2_e2 }
            end

            context "subgroup 1" do
              example("ex 2") { run_order << :g1_e2 }
              example("ex 1") { run_order << :g1_e1 }
              example("ex 3") { run_order << :g1_e3 }
            end

            context "subgroup 3" do
              example("ex 2") { run_order << :g3_e2 }
              example("ex 3") { run_order << :g3_e3 }
              example("ex 1") { run_order << :g3_e1 }
            end
          end

          group.run

          expect(run_order).to eq([
            :e1,    :e2,
            :g1_e1, :g1_e2, :g1_e3,
            :g2_e1, :g2_e2, :g2_e3,
            :g3_e1, :g3_e2, :g3_e3
          ])
        end
      end
    end

    describe "top level group" do
      it "runs its children" do
        examples_run = []
        group = RSpec.describe("parent") do
          describe("child") do
            it "does something" do |ex|
              examples_run << ex
            end
          end
        end

        group.run
        expect(examples_run.count).to eq(1)
      end

      context "with a failure in the top level group" do
        it "runs its children " do
          examples_run = []
          group = RSpec.describe("parent") do
            it "fails" do |ex|
              examples_run << ex
              raise "fail"
            end
            describe("child") do
              it "does something" do |ex|
                examples_run << ex
              end
            end
          end

          group.run
          expect(examples_run.count).to eq(2)
        end
      end

      describe "descendants" do
        it "returns self + all descendants" do
          group = RSpec.describe("parent") do
            describe("child") do
              describe("grandchild 1") {}
              describe("grandchild 2") {}
            end
          end
          expect(group.descendants.size).to eq(4)
        end
      end
    end

    describe "child" do
      it "is known by parent" do
        parent = RSpec.describe
        child = parent.describe
        expect(parent.children).to eq([child])
      end

      it "is not registered in world" do
        parent = RSpec.describe
        parent.describe

        expect(RSpec.world.example_groups).to eq([parent])
      end
    end

    describe "filtering" do
      let(:world) { World.new }
      before { allow(RSpec).to receive_messages(:world => self.world) }

      shared_examples "matching filters" do
        context "inclusion" do
          before do
            filter_manager = FilterManager.new
            filter_manager.include filter_metadata
            allow(self.world).to receive_messages(:filter_manager => filter_manager)
          end

          it "includes examples in groups matching filter" do
            group = RSpec.describe("does something", spec_metadata)
            all_examples = [ group.example("first"), group.example("second") ]

            expect(group.filtered_examples).to eq(all_examples)
          end

          it "includes examples directly matching filter" do
            group = RSpec.describe("does something")
            filtered_examples = [
              group.example("first", spec_metadata),
              group.example("second", spec_metadata)
            ]
            group.example("third (not-filtered)")

            expect(group.filtered_examples).to eq(filtered_examples)
          end
        end

        context "exclusion" do
          before do
            filter_manager = FilterManager.new
            filter_manager.exclude filter_metadata
            allow(self.world).to receive_messages(:filter_manager => filter_manager)
          end

          it "excludes examples in groups matching filter" do
            group = RSpec.describe("does something", spec_metadata)
            [ group.example("first"), group.example("second") ]

            expect(group.filtered_examples).to be_empty
          end

          it "excludes examples directly matching filter" do
            group = RSpec.describe("does something")
            [
              group.example("first", spec_metadata),
              group.example("second", spec_metadata)
            ]
            unfiltered_example = group.example("third (not-filtered)")

            expect(group.filtered_examples).to eq([unfiltered_example])
          end
        end
      end

      context "matching false" do
        let(:spec_metadata)    { { :awesome => false }}

        context "against false" do
          let(:filter_metadata)  { { :awesome => false }}
          include_examples "matching filters"
        end

        context "against 'false'" do
          let(:filter_metadata)  { { :awesome => 'false' }}
          include_examples "matching filters"
        end

        context "against :false" do
          let(:filter_metadata)  { { :awesome => :false }}
          include_examples "matching filters"
        end
      end

      context "matching true" do
        let(:spec_metadata)    { { :awesome => true }}

        context "against true" do
          let(:filter_metadata)  { { :awesome => true }}
          include_examples "matching filters"
        end

        context "against 'true'" do
          let(:filter_metadata)  { { :awesome => 'true' }}
          include_examples "matching filters"
        end

        context "against :true" do
          let(:filter_metadata)  { { :awesome => :true }}
          include_examples "matching filters"
        end
      end

      context "matching a string" do
        let(:spec_metadata)    { { :type => 'special' }}

        context "against a string" do
          let(:filter_metadata)  { { :type => 'special' }}
          include_examples "matching filters"
        end

        context "against a symbol" do
          let(:filter_metadata)  { { :type => :special }}
          include_examples "matching filters"
        end
      end

      context "matching a symbol" do
        let(:spec_metadata)    { { :type => :special }}

        context "against a string" do
          let(:filter_metadata)  { { :type => 'special' }}
          include_examples "matching filters"
        end

        context "against a symbol" do
          let(:filter_metadata)  { { :type => :special }}
          include_examples "matching filters"
        end
      end

      context "with no filters" do
        it "returns all" do
          group = RSpec.describe
          example = group.example("does something")
          expect(group.filtered_examples).to eq([example])
        end
      end

      context "with no examples or groups that match filters" do
        it "returns none" do
          filter_manager = FilterManager.new
          filter_manager.include :awesome => false
          allow(self.world).to receive_messages(:filter_manager => filter_manager)
          group = RSpec.describe
          group.example("does something")
          expect(group.filtered_examples).to eq([])
        end
      end
    end

    describe '#described_class' do

      context "with a constant as the first parameter" do
        it "is that constant" do
          expect(RSpec.describe(Object) { }.described_class).to eq(Object)
        end
      end

      context "with a string as the first parameter" do
        it "is nil" do
          expect(RSpec.describe("i'm a computer") { }.described_class).to be_nil
        end
      end

      context "with a constant in an outer group" do
        context "and a string in an inner group" do
          it "is the top level constant" do
            group = RSpec.describe(String) do
              describe "inner" do
                example "described_class is String" do
                  expect(described_class).to eq(String)
                end
              end
            end

            expect(group.run).to be(true)
          end
        end

        context "and metadata redefinition after `described_class` call" do
          it "is the redefined level constant" do
            group = RSpec.describe(String) do
              described_class
              metadata[:described_class] = Object
              describe "inner" do
                example "described_class is Object" do
                  expect(described_class).to eq(Object)
                end
              end
            end

            expect(group.run).to be(true)
          end
        end
      end

      context "in a nested group" do
        it "inherits the described class/module from the outer group" do
          group = RSpec.describe(String) do
            describe "nested" do
              example "describes is String" do
                expect(described_class).to eq(String)
              end
            end
          end

          expect(group.run).to be(true), "expected examples in group to pass"
        end

        context "when a class is passed" do
          def described_class_value
            value = nil

            RSpec.describe(String) do
              yield if block_given?
              describe Array do
                example { value = described_class }
              end
            end.run

            value
          end

          it "overrides the described class" do
            expect(described_class_value).to eq(Array)
          end

          it "overrides the described class even when described_class is referenced in the outer group" do
            expect(described_class_value { described_class }).to eq(Array)
          end
        end
      end

      context "for `describe(SomeClass)` within a `describe 'some string' group" do
        def define_and_run_group(define_outer_example = false)
          outer_described_class = inner_described_class = nil

          RSpec.describe("some string") do
            example { outer_described_class = described_class } if define_outer_example

            describe Array do
              example { inner_described_class = described_class }
            end
          end.run

          return outer_described_class, inner_described_class
        end

        it "has a `nil` described_class in the outer group" do
          outer_described_class, _ = define_and_run_group(:define_outer_example)
          expect(outer_described_class).to be(nil)
        end

        it "has the inner described class as the described_class of the inner group" do
          _, inner_described_class = define_and_run_group
          expect(inner_described_class).to be(Array)

          # This is weird, but in RSpec 2.12 (and before, presumably),
          # the `described_class` value would be incorrect if there was an
          # example in the outer group, and correct if there was not one.
          _, inner_described_class = define_and_run_group(:define_outer_example)
          expect(inner_described_class).to be(Array)
        end
      end
    end

    describe '#described_class' do
      it "is the same as described_class" do
        expect(self.class.described_class).to eq(self.class.described_class)
      end
    end

    describe '#description' do
      it "grabs the description from the metadata" do
        group = RSpec.describe(Object, "my desc") { }
        expect(group.description).to eq(group.metadata[:description])
      end
    end

    describe '#metadata' do
      it "adds the third parameter to the metadata" do
        expect(RSpec.describe(Object, nil, 'foo' => 'bar') { }.metadata).to include({ "foo" => 'bar' })
      end

      it "adds the the file_path to metadata" do
        expect(RSpec.describe(Object) { }.metadata[:file_path]).to eq(relative_path(__FILE__))
      end

      it "has a reader for file_path" do
        expect(RSpec.describe(Object) { }.file_path).to eq(relative_path(__FILE__))
      end

      it "adds the line_number to metadata" do
        expect(RSpec.describe(Object) { }.metadata[:line_number]).to eq(__LINE__)
      end
    end

    [:focus, :fexample, :fit, :fspecify].each do |example_alias|
      describe ".#{example_alias}" do
        let(:focused_example) { RSpec.describe.send example_alias, "a focused example" }

        it 'defines an example that can be filtered with :focus => true' do
          expect(focused_example.metadata[:focus]).to be(true)
        end
      end
    end

    describe "#before, after, and around hooks" do
      describe "scope aliasing" do
        it "aliases the `:context` hook scope to `:all` for before-hooks" do
          group = RSpec.describe
          order = []
          group.before(:context) { order << :before_context }
          group.example("example") { order << :example }
          group.example("example") { order << :example }

          group.run
          expect(order).to eq([:before_context, :example, :example])
        end

        it "aliases the `:example` hook scope to `:each` for before-hooks" do
          group = RSpec.describe
          order = []
          group.before(:example) { order << :before_example }
          group.example("example") { order << :example }
          group.example("example") { order << :example }

          group.run
          expect(order).to eq([:before_example, :example, :before_example, :example])
        end

        it "aliases the `:context` hook scope to `:all` for after-hooks" do
          group = RSpec.describe
          order = []
          group.example("example") { order << :example }
          group.example("example") { order << :example }
          group.after(:context) { order << :after_context }

          group.run
          expect(order).to eq([:example, :example, :after_context])
        end

        it "aliases the `:example` hook scope to `:each` for after-hooks" do
          group = RSpec.describe
          order = []
          group.example("example") { order << :example }
          group.example("example") { order << :example }
          group.after(:example) { order << :after_example }

          group.run
          expect(order).to eq([:example, :after_example, :example, :after_example])
        end

        describe "#currently_executing_a_context_hook?" do
          it "sets currently_executing_a_context_hook? to false initially" do
            group = RSpec.describe
            expect(group.currently_executing_a_context_hook?).to be false
          end

          it "sets currently_executing_a_context_hook? during before(:context) execution" do
            group = RSpec.describe
            hook_result = nil
            group.before(:context) { hook_result = group.currently_executing_a_context_hook? }
            group.example("") {}
            group.run
            expect(hook_result).to be true
          end

          it "does not set currently_executing_a_context_hook? outside of before(:context) execution" do
            group = RSpec.describe
            hook_result = nil

            group.before(:context) { hook_result = group.currently_executing_a_context_hook? }
            group.before(:each) { hook_result = group.currently_executing_a_context_hook? }
            group.example("") {}
            group.run
            expect(hook_result).to be false
          end

          it "sets currently_executing_a_context_hook? during after(:context) execution" do
            group = RSpec.describe
            hook_result = nil

            group.after(:context) { hook_result = group.currently_executing_a_context_hook? }
            group.example("") {}
            group.run
            expect(hook_result).to be true
          end

          it "unsets currently_executing_a_context_hook? after an after(:context) hook is done" do
            group = RSpec.describe
            group.after(:context) { }
            group.example("") {}
            group.run
            expect(group.currently_executing_a_context_hook?).to be false
          end
        end
      end

      it "runs the before alls in order" do
        group = RSpec.describe
        order = []
        group.before(:all) { order << 1 }
        group.before(:all) { order << 2 }
        group.before(:all) { order << 3 }
        group.example("example") {}

        group.run

        expect(order).to eq([1,2,3])
      end

      it "does not set RSpec.world.wants_to_quit in case of an error in before all (without fail_fast?)" do
        group = RSpec.describe
        group.before(:all) { raise "error in before all" }
        group.example("example") {}

        group.run
        expect(RSpec.world.wants_to_quit).to be(false)
      end

      it "runs the before eachs in order" do
        group = RSpec.describe
        order = []
        group.before(:each) { order << 1 }
        group.before(:each) { order << 2 }
        group.before(:each) { order << 3 }
        group.example("example") {}

        group.run

        expect(order).to eq([1,2,3])
      end

      it "runs the after eachs in reverse order" do
        group = RSpec.describe
        order = []
        group.after(:each) { order << 1 }
        group.after(:each) { order << 2 }
        group.after(:each) { order << 3 }
        group.example("example") {}

        group.run

        expect(order).to eq([3,2,1])
      end

      it "runs the after alls in reverse order" do
        group = RSpec.describe
        order = []
        group.after(:all) { order << 1 }
        group.after(:all) { order << 2 }
        group.after(:all) { order << 3 }
        group.example("example") {}

        group.run

        expect(order).to eq([3,2,1])
      end

      it "only runs before/after(:all) hooks from example groups that have specs that run" do
        hooks_run = []

        RSpec.configure do |c|
          c.filter_run :focus => true
        end

        unfiltered_group = RSpec.describe "unfiltered" do
          before(:all) { hooks_run << :unfiltered_before_all }
          after(:all)  { hooks_run << :unfiltered_after_all  }

          context "a subcontext" do
            it("has an example") { }
          end
        end

        filtered_group = RSpec.describe "filtered", :focus => true do
          before(:all) { hooks_run << :filtered_before_all }
          after(:all)  { hooks_run << :filtered_after_all  }

          context "a subcontext" do
            it("has an example") { }
          end
        end

        unfiltered_group.run
        filtered_group.run

        expect(hooks_run).to eq([:filtered_before_all, :filtered_after_all])
      end

      it "runs before_all_defined_in_config, before all, before each, example, after each, after all, after_all_defined_in_config in that order" do
        order = []

        RSpec.configure do |c|
          c.before(:all) { order << :before_all_defined_in_config }
          c.after(:all) { order << :after_all_defined_in_config }
        end

        group = RSpec.describe
        group.before(:all)  { order << :top_level_before_all  }
        group.before(:each) { order << :before_each }
        group.after(:each)  { order << :after_each  }
        group.after(:all)   { order << :top_level_after_all   }
        group.example("top level example") { order << :top_level_example }

        context1 = group.describe("context 1")
        context1.before(:all) { order << :nested_before_all }
        context1.example("nested example 1") { order << :nested_example_1 }

        context2 = group.describe("context 2")
        context2.after(:all) { order << :nested_after_all }
        context2.example("nested example 2") { order << :nested_example_2 }

        group.run

        expect(order).to eq([
          :before_all_defined_in_config,
          :top_level_before_all,
          :before_each,
          :top_level_example,
          :after_each,
          :nested_before_all,
          :before_each,
          :nested_example_1,
          :after_each,
          :before_each,
          :nested_example_2,
          :after_each,
          :nested_after_all,
          :top_level_after_all,
          :after_all_defined_in_config
        ])
      end

      context "after(:all)" do
        let(:outer) { RSpec.describe }
        let(:inner) { outer.describe }

        it "has access to state defined before(:all)" do
          outer.before(:all) { @outer = "outer" }
          inner.before(:all) { @inner = "inner" }

          outer.after(:all) do
            expect(@outer).to eq("outer")
            expect(@inner).to eq("inner")
          end
          inner.after(:all) do
            expect(@inner).to eq("inner")
            expect(@outer).to eq("outer")
          end

          outer.run
        end

        it "cleans up ivars in after(:all)" do
          outer.before(:all) { @outer = "outer" }
          inner.before(:all) { @inner = "inner" }

          outer.run

          expect(inner.before_context_ivars[:@inner]).to be_nil
          expect(inner.before_context_ivars[:@outer]).to be_nil
          expect(outer.before_context_ivars[:@inner]).to be_nil
          expect(outer.before_context_ivars[:@outer]).to be_nil
        end
      end

      it "treats an error in before(:each) as a failure" do
        group = RSpec.describe
        group.before(:each) { raise "error in before each" }
        example = group.example("equality") { expect(1).to eq(2) }
        expect(group.run).to be(false)

        expect(example.execution_result.exception.message).to eq("error in before each")
      end

      it "treats an error in before(:all) as a failure" do
        group = RSpec.describe
        group.before(:all) { raise "error in before all" }
        example = group.example("equality") { expect(1).to eq(2) }
        expect(group.run).to be(false)

        expect(example.metadata).not_to be_nil
        expect(example.execution_result.exception).not_to be_nil
        expect(example.execution_result.exception.message).to eq("error in before all")
      end

      it "exposes instance variables set in before(:all) from after(:all) even if a before(:all) error occurs" do
        ivar_value_in_after_hook = nil

        group = RSpec.describe do
          before(:all) do
            @an_ivar = :set_in_before_all
            raise "fail"
          end

          after(:all) { ivar_value_in_after_hook = @an_ivar }

          it("has a spec") { }
        end

        group.run
        expect(ivar_value_in_after_hook).to eq(:set_in_before_all)
      end

      it "treats an error in before(:all) as a failure for a spec in a nested group" do
        example = nil
        group = RSpec.describe do
          before(:all) { raise "error in before all" }

          describe "nested" do
            example = it("equality") { expect(1).to eq(2) }
          end
        end
        group.run

        expect(example.metadata).not_to be_nil
        expect(example.execution_result.exception).not_to be_nil
        expect(example.execution_result.exception.message).to eq("error in before all")
      end

      context "when an error occurs in an after(:all) hook" do
        hooks_run = []

        before(:each) do
          hooks_run = []
          allow(RSpec.configuration.reporter).to receive(:message)
        end

        let(:group) do
          RSpec.describe do
            after(:all) { hooks_run << :one; raise "An error in an after(:all) hook" }
            after(:all) { hooks_run << :two; raise "A different hook raising an error" }
            it("equality") { expect(1).to eq(1) }
          end
        end

        it "allows the example to pass" do
          self.group.run
          example = self.group.examples.first
          expect(example.execution_result.status).to eq(:passed)
        end

        it "rescues any error(s) and prints them out" do
          expect(RSpec.configuration.reporter).to receive(:message).with(/An error in an after\(:all\) hook/)
          expect(RSpec.configuration.reporter).to receive(:message).with(/A different hook raising an error/)
          self.group.run
        end

        it "still runs both after blocks" do
          self.group.run
          expect(hooks_run).to eq [:two,:one]
        end

        it "sets `world.non_example_failure` so the exit status will be non-zero" do
          expect {
            self.group.run
          }.to change { RSpec.world.non_example_failure }.from(a_falsey_value).to(true)
        end
      end
    end

    describe ".pending" do
      let(:group) { RSpec.describe { pending { fail } } }

      it "generates a pending example" do
        self.group.run
        expect(self.group.examples.first).to be_pending
      end

      it "sets the pending message" do
        self.group.run
        expect(self.group.examples.first.execution_result.pending_message).to eq(RSpec::Core::Pending::NO_REASON_GIVEN)
      end

      it 'sets the backtrace to the example definition so it can be located by the user' do
        file = RSpec::Core::Metadata.relative_path(__FILE__)
        expected = [file, __LINE__ + 2].map(&:to_s)
        group = RSpec.describe do
          pending { }
        end
        group.run

        actual = group.examples.first.exception.backtrace.first.split(':')[0..1]
        expect(actual).to eq(expected)
      end

      it 'generates a pending example when no block is provided' do
        group = RSpec.describe "group"
        example = group.pending "just because"
        group.run
        expect(example).to be_pending
      end
    end

    describe "pending with metadata" do
      let(:group) { RSpec.describe {
        example("unimplemented", :pending => true) { fail }
      } }

      it "generates a pending example" do
        self.group.run
        expect(self.group.examples.first).to be_pending
      end

      it "sets the pending message" do
        self.group.run
        expect(self.group.examples.first.execution_result.pending_message).to eq(RSpec::Core::Pending::NO_REASON_GIVEN)
      end
    end

    describe "pending with message in metadata" do
      let(:group) { RSpec.describe {
        example("unimplemented", :pending => 'not done') { fail }
      } }

      it "generates a pending example" do
        self.group.run
        expect(self.group.examples.first).to be_pending
      end

      it "sets the pending message" do
        self.group.run
        expect(self.group.examples.first.execution_result.pending_message).to eq("not done")
      end
    end

    describe ".skip" do
      let(:group) { RSpec.describe { skip("skip this") { } } }

      it "generates a skipped example" do
        self.group.run
        expect(self.group.examples.first).to be_skipped
      end

      it "sets the pending message" do
        self.group.run
        expect(self.group.examples.first.execution_result.pending_message).to eq(RSpec::Core::Pending::NO_REASON_GIVEN)
      end
    end

    describe "skip with metadata" do
      let(:group) { RSpec.describe {
        example("skip this", :skip => true) { }
      } }

      it "generates a skipped example" do
        self.group.run
        expect(self.group.examples.first).to be_skipped
      end

      it "sets the pending message" do
        self.group.run
        expect(self.group.examples.first.execution_result.pending_message).to eq(RSpec::Core::Pending::NO_REASON_GIVEN)
      end
    end

    describe "skip with message in metadata" do
      let(:group) { RSpec.describe {
        example("skip this", :skip => 'not done') { }
      } }

      it "generates a skipped example" do
        self.group.run
        expect(self.group.examples.first).to be_skipped
      end

      it "sets the pending message" do
        self.group.run
        expect(self.group.examples.first.execution_result.pending_message).to eq('not done')
      end
    end

    %w[xit xspecify xexample].each do |method_name|
      describe ".#{method_name}" do
        let(:group) { RSpec.describe.tap {|x|
          x.send(method_name, "is pending") { }
        }}

        it "generates a skipped example" do
          self.group.run
          expect(self.group.examples.first).to be_skipped
        end

        it "sets the pending message" do
          self.group.run
          expect(self.group.examples.first.execution_result.pending_message).to eq("Temporarily skipped with #{method_name}")
        end
      end
    end

    %w[ xdescribe xcontext ].each do |method_name|
      describe ".#{method_name}" do
        def extract_execution_results(group)
          group.examples.map do |ex|
            ex.metadata.fetch(:execution_result)
          end
        end

        it 'generates a pending example group' do
          group = ExampleGroup.send(method_name, "group") do
            it("passes") { }
            it("fails")  { expect(2).to eq(3) }
          end
          group.run

          expect(extract_execution_results(group).map(&:to_h)).to match([
            a_hash_including(
              :status => :pending,
              :pending_message => "Temporarily skipped with #{method_name}"
            )
          ] * 2)
        end
      end
    end

    %w[ fdescribe fcontext ].each do |method_name|
      describe ".#{method_name}" do
        def executed_examples_of(group)
          examples = group.examples.select { |ex| ex.execution_result.started_at }
          group.children.inject(examples) { |exs, child| exs + executed_examples_of(child) }
        end

        it "generates an example group that can be filtered with :focus" do
          RSpec.configuration.filter_run :focus

          parent_group = RSpec.describe do
            describe "not focused" do
              example("not focused example") { }
            end

            send(method_name, "focused") do
              example("focused example") { }
            end
          end

          parent_group.run

          executed_descriptions = executed_examples_of(parent_group).map(&:description)
          expect(executed_descriptions).to eq(["focused example"])
        end
      end
    end

    describe "setting pending metadata in parent" do
      def extract_execution_results(group)
        group.examples.map do |ex|
          ex.metadata.fetch(:execution_result)
        end
      end

      it 'marks every example as pending' do
        group = RSpec.describe("group", :pending => true) do
          it("passes") { }
          it("fails", :pending => 'unimplemented')  { fail }
        end
        group.run

        expect(extract_execution_results(group).map(&:to_h)).to match([
          a_hash_including(
            :status => :failed,
            :pending_message => "No reason given"
          ),
          a_hash_including(
            :status => :pending,
            :pending_message => "unimplemented"
          )
        ])
      end
    end

    describe "adding examples" do

      it "allows adding an example using 'it'" do
        group = RSpec.describe
        group.it("should do something") { }
        expect(group.examples.size).to eq(1)
      end

      it "exposes all examples at examples" do
        group = RSpec.describe
        group.it("should do something 1") { }
        group.it("should do something 2") { }
        group.it("should do something 3") { }
        expect(group.examples.count).to eq(3)
      end

      it "maintains the example order" do
        group = RSpec.describe
        group.it("should 1") { }
        group.it("should 2") { }
        group.it("should 3") { }
        expect(group.examples[0].description).to eq('should 1')
        expect(group.examples[1].description).to eq('should 2')
        expect(group.examples[2].description).to eq('should 3')
      end

    end

    describe Object, "describing nested example_groups", :little_less_nested => 'yep' do

      describe "A sample nested group", :nested_describe => "yep" do
        it "sets the described class to the nearest described class" do |ex|
          expect(ex.example_group.described_class).to eq(Object)
        end

        it "sets the description to 'A sample nested describe'" do |ex|
          expect(ex.example_group.description).to eq('A sample nested group')
        end

        it "has top level metadata from the example_group and its parent groups" do |ex|
          expect(ex.example_group.metadata).to include(:little_less_nested => 'yep', :nested_describe => 'yep')
        end

        it "exposes the parent metadata to the contained examples" do |ex|
          expect(ex.metadata).to include(:little_less_nested => 'yep', :nested_describe => 'yep')
        end
      end

    end

    describe "#run_examples" do
      let(:reporter) { RSpec::Core::NullReporter }

      it "returns true if all examples pass" do
        group = RSpec.describe('group') do
          example('ex 1') { expect(1).to eq(1) }
          example('ex 2') { expect(1).to eq(1) }
        end
        allow(group).to receive(:filtered_examples) { group.examples }
        expect(group.run(reporter)).to be(true)
      end

      it "returns false if any of the examples fail" do
        group = RSpec.describe('group') do
          example('ex 1') { expect(1).to eq(1) }
          example('ex 2') { expect(1).to eq(2) }
        end
        allow(group).to receive(:filtered_examples) { group.examples }
        expect(group.run(reporter)).to be(false)
      end

      it "runs all examples, regardless of any of them failing" do
        group = RSpec.describe('group') do
          example('ex 1') { expect(1).to eq(2) }
          example('ex 2') { expect(1).to eq(1) }
        end
        allow(group).to receive(:filtered_examples) { group.examples }
        group.filtered_examples.each do |example|
          expect(example).to receive(:run)
        end
        expect(group.run(reporter)).to be(false)
      end
    end

    describe "how instance variables are inherited" do
      before(:all) do
        @before_all_top_level = 'before_all_top_level'
      end

      before(:each) do
        @before_each_top_level = 'before_each_top_level'
      end

      it "can access a before each ivar at the same level" do
        expect(@before_each_top_level).to eq('before_each_top_level')
      end

      it "can access a before all ivar at the same level" do
        expect(@before_all_top_level).to eq('before_all_top_level')
      end

      it "can access the before all ivars in the before_all_ivars hash", :ruby => 1.8 do |ex|
        expect(ex.example_group.before_context_ivars).to include('@before_all_top_level' => 'before_all_top_level')
      end

      it "can access the before all ivars in the before_all_ivars hash", :ruby => 1.9 do |ex|
        expect(ex.example_group.before_context_ivars).to include(:@before_all_top_level => 'before_all_top_level')
      end

      describe "but now I am nested" do
        it "can access a parent example groups before each ivar at a nested level" do
          expect(@before_each_top_level).to eq('before_each_top_level')
        end

        it "can access a parent example groups before all ivar at a nested level" do
          expect(@before_all_top_level).to eq("before_all_top_level")
        end

        it "changes to before all ivars from within an example do not persist outside the current describe" do
          @before_all_top_level = "ive been changed"
        end

        describe "accessing a before_all ivar that was changed in a parent example_group" do
          it "does not have access to the modified version" do
            expect(@before_all_top_level).to eq('before_all_top_level')
          end
        end
      end

    end

    describe "ivars are not shared across examples" do
      it "(first example)" do
        @a = 1
        expect(defined?(@b)).to be(nil)
      end

      it "(second example)" do
        @b = 2
        expect(defined?(@a)).to be(nil)
      end
    end


    describe "#top_level_description" do
      it "returns the description from the outermost example group" do
        group = nil
        RSpec.describe("top") do
          context "middle" do
            group = describe "bottom" do
            end
          end
        end

        expect(group.top_level_description).to eq("top")
      end
    end

    describe "#run" do
      context "with `fail_fast` set to `nil`" do
        before { RSpec.configuration.fail_fast = nil }
        let(:group) { RSpec.describe }
        let(:reporter) { Reporter.new(RSpec.configuration) }

        it "does not run abort due to failures" do
          examples_run = []
          group().example('example 1') { examples_run << self; fail }
          group().example('example 2') { examples_run << self; fail }
          group().example('example 3') { examples_run << self; fail }

          group().run(reporter)

          expect(examples_run.length).to eq(3)
        end
      end

      context "with fail_fast enabled" do
        before { RSpec.configuration.fail_fast = true }
        let(:group) { RSpec.describe }
        let(:reporter) { Reporter.new(RSpec.configuration) }

        it "does not run examples after the failed example" do
          examples_run = []
          group().example('example 1') { examples_run << self }
          group().example('example 2') { examples_run << self; fail; }
          group().example('example 3') { examples_run << self }

          group().run(reporter)

          expect(examples_run.length).to eq(2)
        end

        it "sets RSpec.world.wants_to_quit flag if encountering an exception in before(:all)" do
          group().before(:all) { raise "error in before all" }
          group().example("equality") { expect(1).to eq(2) }
          expect(group().run(reporter)).to be(false)
          expect(RSpec.world.wants_to_quit).to be(true)
        end
      end

      context "with fail_fast set to 3" do
        before { RSpec.configuration.fail_fast = 3 }
        let(:group) { RSpec.describe }
        let(:reporter) { Reporter.new(RSpec.configuration) }

        it "does not run examples after 3 failed examples" do
          examples_run = []
          group().example('example 1') { examples_run << self }
          group().example('example 2') { examples_run << self; fail; }
          group().example('example 3') { examples_run << self; fail; }
          group().example('example 4') { examples_run << self; fail; }
          group().example('example 5') { examples_run << self }

          group().run(reporter)

          expect(examples_run.length).to eq(4)
        end

        it "does not set RSpec.world.wants_to_quit flag if encountering an exception in before(:all) causing less than 3 failures" do
          group().before(:all) { raise "error in before all" }
          group().example("equality") { expect(1).to eq(2) }
          group().example("equality") { expect(1).to eq(2) }

          expect(group().run(reporter)).to be false

          expect(RSpec.world.wants_to_quit).to be(false)
        end

        it "sets RSpec.world.wants_to_quit flag if encountering an exception in before(:all) causing at least 3 failures" do
          group().before(:all) { raise "error in before all" }
          group().example("equality") { expect(1).to eq(1) }
          group().example("equality") { expect(1).to eq(1) }
          group().example("equality") { expect(1).to eq(1) }

          expect(group().run(reporter)).to be false

          expect(RSpec.world.wants_to_quit).to be true
        end
      end

      let(:reporter) { double("reporter").as_null_object }

      context "with RSpec.world.wants_to_quit=true" do
        let(:group) { RSpec.describe }

        before do
          RSpec.world.wants_to_quit = true
        end

        it "returns without starting the group" do
          expect(reporter).not_to receive(:example_group_started)
          group().run(reporter)
        end
      end

      context "with all examples passing" do
        it "returns true" do
          group = RSpec.describe("something") do
            it "does something" do
              # pass
            end
            describe "nested" do
              it "does something else" do
                # pass
              end
            end
          end

          expect(group.run(reporter)).to be(true)
        end
      end

      context "with top level example failing" do
        it "returns false" do
          group = RSpec.describe("something") do
            it "does something (wrong - fail)" do
              raise "fail"
            end
            describe "nested" do
              it "does something else" do
                # pass
              end
            end
          end

          expect(group.run(reporter)).to be(false)
        end
      end

      context "with nested example failing" do
        it "returns true" do
          group = RSpec.describe("something") do
            it "does something" do
              # pass
            end
            describe "nested" do
              it "does something else (wrong -fail)" do
                raise "fail"
              end
            end
          end

          expect(group.run(reporter)).to be(false)
        end
      end
    end

    describe "#update_inherited_metadata" do
      it "updates the group metadata with the provided hash" do
        group = RSpec.describe

        expect(group.metadata).not_to include(:foo => 1, :bar => 2)
        group.update_inherited_metadata(:foo => 1, :bar => 2)
        expect(group.metadata).to include(:foo => 1, :bar => 2)
      end

      it "does not overwrite existing metadata originating from that level" do
        group = RSpec.describe("group", :foo => 1)

        expect {
          group.update_inherited_metadata(:foo => 2)
        }.not_to change { group.metadata[:foo] }.from(1)
      end

      it "overwrites metadata originating from a parent" do
        group = nil
        RSpec.describe("group", :foo => 1) do
          group = context do
          end
        end

        expect {
          group.update_inherited_metadata(:foo => 2)
        }.to change { group.metadata[:foo] }.from(1).to(2)
      end

      it "does not replace the existing metadata object with a new one or change its default proc" do
        group = RSpec.describe

        expect {
          group.update_inherited_metadata(:foo => 1)
        }.to avoid_changing { group.metadata.__id__ }.and avoid_changing { group.metadata.default_proc }
      end

      it "propogates metadata updates to previously declared child examples" do
        group = RSpec.describe
        example = group.example

        expect {
          group.update_inherited_metadata(:foo => 1)
        }.to change { example.metadata[:foo] }.from(nil).to(1)
      end

      it "propogates metadata updates to previously declared child group" do
        group = RSpec.describe
        child_group = group.describe

        expect {
          group.update_inherited_metadata(:foo => 1)
        }.to change { child_group.metadata[:foo] }.from(nil).to(1)
      end

      it "applies new metadata-based config items based on the update" do
        extension = Module.new do
          def extension_method; 17; end
        end

        sequence = []
        extension_checks = []
        RSpec.configure do |c|
          c.before(:example, :foo => true) { sequence << :global_before_hook }
          c.after(:example, :foo => true) { sequence << :global_after_hook }
          c.extend extension, :foo => true
        end

        describe_successfully do
          example { sequence << :example_1 }

          extension_checks << begin
            self.extension_method
          rescue NoMethodError
            :method_not_defined
          end

          context "nested group before update" do
            example { sequence << :nested_example }
          end

          update_inherited_metadata(:foo => true)

          extension_checks << begin
            self.extension_method
          rescue NoMethodError
            :method_not_defined
          end

          example { sequence << :example_2 }
        end

        expect(sequence).to eq [
          :global_before_hook, :example_1, :global_after_hook,
          :global_before_hook, :example_2, :global_after_hook,
          :global_before_hook, :nested_example, :global_after_hook,
        ]

        expect(extension_checks).to eq [:method_not_defined, 17]
      end

      it "does not cause duplicate hooks to be added when re-configuring the group" do
        sequence = []
        RSpec.configure do |c|
          c.before(:example, :foo => true) { sequence << :global_before_hook }
          c.after(:example, :foo => true) { sequence << :global_after_hook }
        end

        describe_successfully("Group", :foo => true) do
         example { sequence << :example_1 }
         update_inherited_metadata(:bar => true)
         example { sequence << :example_2 }
        end

        expect(sequence).to eq [
          :global_before_hook, :example_1, :global_after_hook,
          :global_before_hook, :example_2, :global_after_hook,
        ]
      end
    end

    %w[include_examples include_context].each do |name|
      describe "##{name}" do
        let(:group) { RSpec.describe }
        before do
          self.group.shared_examples "named this" do
            example("does something") {}
          end
        end

        it "includes the named examples" do
          self.group.send(name, "named this")
          expect(self.group.examples.first.description).to eq("does something")
        end

        it "raises a helpful error message when shared content is not found" do
          expect do
            self.group.send(name, "shared stuff")
          end.to raise_error(ArgumentError, /Could not find .* "shared stuff"/)
        end

        it "raises a helpful error message when shared content is accessed recursively" do
          self.group.shared_examples "named otherwise" do
            example("does something") {}
            self.send(name, "named otherwise")
          end
          expect do
            self.group.send(name, "named otherwise")
          end.to raise_error(ArgumentError, /can't include shared examples recursively/)
        end

        it "leaves RSpec's thread metadata unchanged" do
          expect {
            self.group.send(name, "named this")
          }.to avoid_changing(RSpec::Support, :thread_local_data)
        end

        it "leaves RSpec's thread metadata unchanged, even when an error occurs during evaluation" do
          expect {
            self.group.send(name, "named this") do
              raise "boom"
            end
          }.to raise_error("boom").and avoid_changing(RSpec::Support, :thread_local_data)
        end

        it "passes parameters to the shared content" do
          passed_params = {}
          group = RSpec.describe

          group.shared_examples "named this with params" do |param1, param2|
            it("has access to the given parameters") do
              passed_params[:param1] = param1
              passed_params[:param2] = param2
            end
          end

          group.send(name, "named this with params", :value1, :value2)
          group.run

          expect(passed_params).to eq({ :param1 => :value1, :param2 => :value2 })
        end

        it "adds shared instance methods to the group" do
          group = RSpec.describe('fake group')
          group.shared_examples "named this with params" do |param1|
            def foo; end
          end
          group.send(name, "named this with params", :a)
          expect(group.public_instance_methods.map{|m| m.to_s}).to include("foo")
        end

        it "evals the shared example group only once" do
          eval_count = 0
          group = RSpec.describe('fake group')
          group.shared_examples("named this with params") { |p| eval_count += 1 }
          group.send(name, "named this with params", :a)
          expect(eval_count).to eq(1)
        end

        it "evals the block when given" do
          key = "#{__FILE__}:#{__LINE__}"
          group = RSpec.describe do
            shared_examples(key) do
              it("does something") do
                expect(foo).to eq("bar")
              end
            end

            send name, key do
              def foo; "bar"; end
            end
          end
          expect(group.run).to be(true)
        end
      end
    end

    describe "#it_should_behave_like" do
      it "creates a nested group" do
        group = RSpec.describe('fake group')
        group.shared_examples_for("thing") {}
        group.it_should_behave_like("thing")
        expect(group.children.count).to eq(1)
      end

      it "creates a nested group for a class" do
        klass = Class.new
        group = RSpec.describe('fake group')
        group.shared_examples_for(klass) {}
        group.it_should_behave_like(klass)
        expect(group.children.count).to eq(1)
      end

      it "adds shared examples to nested group" do
        group = RSpec.describe('fake group')
        group.shared_examples_for("thing") do
          it("does something")
        end
        shared_group = group.it_should_behave_like("thing")
        expect(shared_group.examples.count).to eq(1)
      end

      it "adds shared instance methods to nested group" do
        group = RSpec.describe('fake group')
        group.shared_examples_for("thing") do
          def foo; end
        end
        shared_group = group.it_should_behave_like("thing")
        expect(shared_group.public_instance_methods.map{|m| m.to_s}).to include("foo")
      end

      it "adds shared class methods to nested group" do
        group = RSpec.describe('fake group')
        group.shared_examples_for("thing") do
          def self.foo; end
        end
        shared_group = group.it_should_behave_like("thing")
        expect(shared_group.methods.map{|m| m.to_s}).to include("foo")
      end

      it "passes parameters to the shared example group" do
        passed_params = {}

        group = RSpec.describe("group") do
          shared_examples_for("thing") do |param1, param2|
            it("has access to the given parameters") do
              passed_params[:param1] = param1
              passed_params[:param2] = param2
            end
          end

          it_should_behave_like "thing", :value1, :value2
        end

        group.run

        expect(passed_params).to eq({ :param1 => :value1, :param2 => :value2 })
      end

      it "adds shared instance methods to nested group" do
        group = RSpec.describe('fake group')
        group.shared_examples_for("thing") do |param1|
          def foo; end
        end
        shared_group = group.it_should_behave_like("thing", :a)
        expect(shared_group.public_instance_methods.map{|m| m.to_s}).to include("foo")
      end

      it "evals the shared example group only once" do
        eval_count = 0
        group = RSpec.describe('fake group')
        group.shared_examples_for("thing") { |p| eval_count += 1 }
        group.it_should_behave_like("thing", :a)
        expect(eval_count).to eq(1)
      end

      context "given a block" do
        it "evaluates the block in nested group" do
          scopes = []
          group = RSpec.describe("group") do
            shared_examples_for("thing") do
              it("gets run in the nested group") do
                scopes << self.class
              end
            end
            it_should_behave_like "thing" do
              it("gets run in the same nested group") do
                scopes << self.class
              end
            end
          end
          group.run

          expect(scopes[0]).to be(scopes[1])
        end
      end

      it "raises a helpful error message when shared context is not found" do
        expect do
          RSpec.describe do
            it_should_behave_like "shared stuff"
          end
        end.to raise_error(ArgumentError,%q|Could not find shared examples "shared stuff"|)
      end

      it "leaves RSpec's thread metadata unchanged" do
        expect {
          RSpec.describe do
            shared_examples_for("stuff") { }
            it_should_behave_like "stuff"
          end
        }.to avoid_changing(RSpec::Support, :thread_local_data)
      end

      it "leaves RSpec's thread metadata unchanged, even when an error occurs during evaluation" do
        expect {
          RSpec.describe do
            shared_examples_for("stuff") { }
            it_should_behave_like "stuff" do
              raise "boom"
            end
          end
        }.to raise_error("boom").and avoid_changing(RSpec::Support, :thread_local_data)
      end
    end

    it 'minimizes the number of methods that users could inadvertantly overwrite' do
      rspec_core_methods = ExampleGroup.instance_methods -
        RSpec::Matchers.instance_methods -
        RSpec::Mocks::ExampleMethods.instance_methods -
        Object.instance_methods -
        ["singleton_class"]

      # Feel free to expand this list if you intend to add another public API
      # for users. RSpec internals should not add methods here, though.
      expect(rspec_core_methods.map(&:to_sym)).to contain_exactly(
        :described_class, :subject,
        :is_expected, :should, :should_not,
        :pending, :skip,
        :setup_mocks_for_rspec, :teardown_mocks_for_rspec, :verify_mocks_for_rspec
      )
    end

    it 'prevents defining nested isolated contexts' do
      expect {
        RSpec.describe do
          describe {}
          RSpec.describe {}
        end
      }.to raise_error(/not allowed/)
    end

    it 'prevents defining nested isolated shared contexts' do
      expect {
        RSpec.describe do
          ExampleGroup.shared_examples("common functionality") {}
        end
      }.to raise_error(/not allowed/)
    end

    describe 'inspect output', :unless => RUBY_VERSION == '1.9.2' do
      context 'when there is no inspect output provided' do
        it "uses '(no description provided)' instead" do
          expect(ExampleGroup.new.inspect).to eq('#<RSpec::Core::ExampleGroup (no description provided)>')
        end
      end

      context 'when an example has a description' do
        it 'includes description and location' do
          an_example = nil

          line = __LINE__ + 2
          group = RSpec.describe 'SomeClass1' do
            example 'an example' do
              an_example = self
            end
          end

          group.run

          path = RSpec::Core::Metadata.relative_path(__FILE__)
          expect(an_example.inspect).to eq("#<RSpec::ExampleGroups::SomeClass1 \"an example\" (#{path}:#{line})>")
        end
      end

      context 'when an example does not have a description' do
        it 'includes fallback description' do
          an_example = nil

          line = __LINE__ + 2
          group = RSpec.describe 'SomeClass2' do
            example do
              an_example = self
            end
          end

          group.run

          path = RSpec::Core::Metadata.relative_path(__FILE__)
          expect(an_example.inspect).to eq("#<RSpec::ExampleGroups::SomeClass2 \"example at #{path}:#{line}\">")
        end
      end

      it 'handles before context hooks' do
        a_before_hook = nil

        group = RSpec.describe 'SomeClass3' do
          before(:context) do
            a_before_hook = self
          end

          example {}
        end

        group.run
        expect(a_before_hook.inspect).to eq("#<RSpec::ExampleGroups::SomeClass3 before(:context) hook>")
      end

      it 'handles after context hooks' do
        an_after_hook = nil

        group = RSpec.describe 'SomeClass4' do
          after(:context) do
            an_after_hook = self
          end

          example {}
        end

        group.run
        expect(an_after_hook.inspect).to eq("#<RSpec::ExampleGroups::SomeClass4 after(:context) hook>")
      end

      it "does not pollute an example's `inspect` output with the inspect ivar from `before(:context)`" do
        inspect_output = nil

        line = __LINE__ + 2
        group = RSpec.describe do
          example do
            inspect_output = inspect
          end

          before(:context) {}
        end

        group.run

        path = RSpec::Core::Metadata.relative_path(__FILE__)
        expect(inspect_output).to end_with("\"example at #{path}:#{line}\">")
      end
    end

    def group_ids group
      ids = []
      ['descendant_filtered_examples', 'descendants',
       'parent_groups', 'declaration_locations', 'before_context_ivars'].each do |method|
        ids << group.send(method).object_id
      end
      ids
    end

    it 'allows adding examples' do
      group = RSpec.describe('group') do
          example('ex 1') { expect(1).to eq(1) }
      end

      # ids should remain the same until we add/remove an example
      original_ids = group_ids group
      expect(original_ids).to eq(group_ids(group))

      group.add_example group.examples.first
      expect(group.examples.length).to eq(2)
      expect(original_ids).to_not eq(group_ids(group))
    end

    it 'allows removing examples' do
      group = RSpec.describe('group') do
        example('ex 1') { expect(1).to eq(1) }
      end
      group.add_example group.examples.first

      # ids should remain the same until we add/remove an example
      original_ids = group_ids group
      expect(original_ids).to eq(group_ids(group))

      group.remove_example group.examples.first
      expect(group.examples.length).to eq(0)
      expect(original_ids).to_not eq(group_ids(group))
    end
  end
end
