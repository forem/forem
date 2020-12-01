module RSpec::Core
  RSpec.describe "config block hook filtering" do
    context "when hooks are defined after a group has been defined" do
      it "still applies" do
        sequence = []

        group = RSpec.describe do
          example { sequence << :ex_1 }
          example { sequence << :ex_2 }
        end

        RSpec.configure do |c|
          c.before(:context) { sequence << :before_cont_2 }
          c.prepend_before(:context) { sequence << :before_cont_1 }

          c.before(:example) { sequence << :before_ex_2 }
          c.prepend_before(:example) { sequence << :before_ex_1 }

          c.after(:context)  { sequence << :after_cont_1 }
          c.append_after(:context) { sequence << :after_cont_2 }

          c.after(:example)  { sequence << :after_ex_1 }
          c.append_after(:example) { sequence << :after_ex_2 }

          c.around(:example) do |ex|
            sequence << :around_before_ex
            ex.run
            sequence << :around_after_ex
          end
        end

        group.run

        expect(sequence).to eq [
          :before_cont_1, :before_cont_2,
          :around_before_ex, :before_ex_1, :before_ex_2, :ex_1, :after_ex_1, :after_ex_2, :around_after_ex,
          :around_before_ex, :before_ex_1, :before_ex_2, :ex_2, :after_ex_1, :after_ex_2, :around_after_ex,
          :after_cont_1, :after_cont_2
        ]
      end

      it "applies only to groups with matching metadata" do
        sequence = []

        unmatching_group = RSpec.describe do
          example { }
          example { }
        end

        matching_group = RSpec.describe "", :run_hooks do
          example { sequence << :ex_1 }
          example { sequence << :ex_2 }
        end

        RSpec.configure do |c|
          c.before(:context, :run_hooks) { sequence << :before_cont_2 }
          c.prepend_before(:context, :run_hooks) { sequence << :before_cont_1 }

          c.before(:example, :run_hooks) { sequence << :before_ex_2 }
          c.prepend_before(:example, :run_hooks) { sequence << :before_ex_1 }

          c.after(:context, :run_hooks)  { sequence << :after_cont_1 }
          c.append_after(:context, :run_hooks) { sequence << :after_cont_2 }

          c.after(:example, :run_hooks)  { sequence << :after_ex_1 }
          c.append_after(:example, :run_hooks) { sequence << :after_ex_2 }

          c.around(:example, :run_hooks) do |ex|
            sequence << :around_before_ex
            ex.run
            sequence << :around_after_ex
          end
        end

        expect { unmatching_group.run }.not_to change { sequence }.from([])

        matching_group.run
        expect(sequence).to eq [
          :before_cont_1, :before_cont_2,
          :around_before_ex, :before_ex_1, :before_ex_2, :ex_1, :after_ex_1, :after_ex_2, :around_after_ex,
          :around_before_ex, :before_ex_1, :before_ex_2, :ex_2, :after_ex_1, :after_ex_2, :around_after_ex,
          :after_cont_1, :after_cont_2
        ]
      end

      { ":example" => [:example], ":each" => [:each] }.each do |label, args|
        args << :run_hooks
        it "applies only to examples with matching metadata (for hooks declared with #{label})" do
          sequence = []

          group = RSpec.describe do
            example("") { sequence << :ex_1 }
            example("", :run_hooks) { sequence << :ex_2 }
          end

          RSpec.configure do |c|
            c.before(*args) { sequence << :before_ex_2 }
            c.prepend_before(*args) { sequence << :before_ex_1 }

            c.after(*args)  { sequence << :after_ex_1 }
            c.append_after(*args) { sequence << :after_ex_2 }

            c.around(*args) do |ex|
              sequence << :around_before_ex
              ex.run
              sequence << :around_after_ex
            end
          end

          group.run
          expect(sequence).to eq [
            :ex_1,
            :around_before_ex, :before_ex_1, :before_ex_2, :ex_2, :after_ex_1, :after_ex_2, :around_after_ex,
          ]
        end
      end

      it "does not apply `suite` hooks to groups (or print warnings about suite hooks applied to example groups)" do
        sequence = []

        group = RSpec.describe do
          example { sequence << :example }
        end

        RSpec.configure do |c|
          c.before(:suite) { sequence << :before_suite }
          c.prepend_before(:suite) { sequence << :prepended_before_suite }
          c.after(:suite) { sequence << :after_suite }
          c.append_after(:suite) { sequence << :appended_after_suite }
        end

        group.run
        expect(sequence).to eq [:example]
      end

      it "only runs example hooks once when there are multiple nested example groups" do
        sequence = []

        group = RSpec.describe do
          context do
            example { sequence << :ex_1 }
            example { sequence << :ex_2 }
          end
        end

        RSpec.configure do |c|
          c.before(:example) { sequence << :before_ex_2 }
          c.prepend_before(:example) { sequence << :before_ex_1 }

          c.after(:example)  { sequence << :after_ex_1 }
          c.append_after(:example) { sequence << :after_ex_2 }

          c.around(:example) do |ex|
            sequence << :around_before_ex
            ex.run
            sequence << :around_after_ex
          end
        end

        group.run

        expect(sequence).to eq [
          :around_before_ex, :before_ex_1, :before_ex_2, :ex_1, :after_ex_1, :after_ex_2, :around_after_ex,
          :around_before_ex, :before_ex_1, :before_ex_2, :ex_2, :after_ex_1, :after_ex_2, :around_after_ex
        ]
      end

      it "only runs context hooks around the highest level group with matching filters" do
        sequence = []

        group = RSpec.describe do
          before(:context) { sequence << :before_context }
          after(:context)  { sequence << :after_context }

          context "", :match do
            context "", :match do
              example { sequence << :example }
            end
          end
        end

        RSpec.configure do |config|
          config.before(:context, :match) { sequence << :before_hook }
          config.after(:context, :match)  { sequence << :after_hook }
        end

        group.run

        expect(sequence).to eq [:before_context, :before_hook, :example, :after_hook, :after_context]
      end
    end

    describe "unfiltered hooks" do
      it "is run" do
        filters = []
        RSpec.configure do |c|
          c.before(:all) { filters << "before all in config"}
          c.around(:each) {|example| filters << "around each in config"; example.run}
          c.before(:each) { filters << "before each in config"}
          c.after(:each) { filters << "after each in config"}
          c.after(:all) { filters << "after all in config"}
        end
        group = RSpec.describe
        group.example("example") {}
        group.run
        expect(filters).to eq([
          "before all in config",
          "around each in config",
          "before each in config",
          "after each in config",
          "after all in config"
        ])
      end
    end

    describe "hooks with single filters" do

      context "with no scope specified" do
        it "is run around|before|after :each if the filter matches the example group's filter" do
          filters = []
          RSpec.configure do |c|
            c.around(:match => true) {|example| filters << "around each in config"; example.run}
            c.before(:match => true) { filters << "before each in config"}
            c.after(:match => true)  { filters << "after each in config"}
          end
          group = RSpec.describe("group", :match => true)
          group.example("example") {}
          group.run
          expect(filters).to eq([
            "around each in config",
            "before each in config",
            "after each in config"
          ])
        end
      end

      it "is run if the filter matches the example group's filter" do
        filters = []
        RSpec.configure do |c|
          c.before(:all,  :match => true) { filters << "before all in config"}
          c.around(:each, :match => true) {|example| filters << "around each in config"; example.run}
          c.before(:each, :match => true) { filters << "before each in config"}
          c.after(:each,  :match => true) { filters << "after each in config"}
          c.after(:all,   :match => true) { filters << "after all in config"}
        end
        group = RSpec.describe("group", :match => true)
        group.example("example") {}
        group.run
        expect(filters).to eq([
          "before all in config",
          "around each in config",
          "before each in config",
          "after each in config",
          "after all in config"
        ])
      end

      it "runs before|after :all hooks on matching nested example groups" do
        filters = []
        RSpec.configure do |c|
          c.before(:all, :match => true) { filters << :before_all }
          c.after(:all, :match => true)  { filters << :after_all }
        end

        example_1_filters = example_2_filters = nil

        group = RSpec.describe "group" do
          it("example 1") { example_1_filters = filters.dup }
          describe "subgroup", :match => true do
            it("example 2") { example_2_filters = filters.dup }
          end
        end
        group.run

        expect(example_1_filters).to be_empty
        expect(example_2_filters).to eq([:before_all])
        expect(filters).to eq([:before_all, :after_all])
      end

      it "runs before|after :all hooks only on the highest level group that matches the filter" do
        filters = []
        RSpec.configure do |c|
          c.before(:all, :match => true) { filters << :before_all }
          c.after(:all, :match => true)  { filters << :after_all }
        end

        example_1_filters = example_2_filters = example_3_filters = nil

        group = RSpec.describe "group", :match => true do
          it("example 1") { example_1_filters = filters.dup }
          describe "subgroup", :match => true do
            it("example 2") { example_2_filters = filters.dup }
            describe "sub-subgroup", :match => true do
              it("example 3") { example_3_filters = filters.dup }
            end
          end
        end
        group.run

        expect(example_1_filters).to eq([:before_all])
        expect(example_2_filters).to eq([:before_all])
        expect(example_3_filters).to eq([:before_all])

        expect(filters).to eq([:before_all, :after_all])
      end

      it "does not run if the filter doesn't match the example group's filter" do
        filters = []
        RSpec.configure do |c|
          c.before(:all,  :match => false) { filters << "before all in config"}
          c.around(:each, :match => false) {|example| filters << "around each in config"; example.run}
          c.before(:each, :match => false) { filters << "before each in config"}
          c.after(:each,  :match => false) { filters << "after each in config"}
          c.after(:all,   :match => false) { filters << "after all in config"}
        end
        group = RSpec.describe(:match => true)
        group.example("example") {}
        group.run
        expect(filters).to eq([])
      end

      it "runs :all|:context hooks even if there are no unskipped examples in that context" do
        filters = []
        group = RSpec.describe("un-skipped describe") do
          before(:all) { filters << "before all in group"}
          after(:all) { filters << "after all in group"}

          xcontext("skipped context") do
            before(:context) { filters << "before context in group"}
            after(:context) { filters << "after context in group"}

            it("is skipped") {}
          end
        end
        group.run
        expect(filters).to eq(["before all in group", "after all in group"])
      end

      it "does not run :all|:context hooks in global config if the entire context is skipped" do
        filters = []
        RSpec.configure do |c|
          c.before(:all) { filters << "before all in config"}
          c.after(:all) { filters << "after all in config"}
          c.before(:context) { filters << "before context in config"}
          c.after(:context) { filters << "after context in config"}
        end
        group = RSpec.xdescribe("skipped describe") do
          context("skipped context") do
            it("is skipped") {}
          end
        end
        group.run
        expect(filters).to eq([])
      end

      it "does not run local :all|:context hooks if the entire context is skipped" do
        filters = []
        group = RSpec.xdescribe("skipped describe") do
          before(:all) { filters << "before all in group"}
          after(:all) { filters << "after all in group"}

          context("skipped context") do
            before(:context) { filters << "before context in group"}
            after(:context) { filters << "after context in group"}

            it("is skipped") {}
          end
        end
        group.run
        expect(filters).to eq([])
      end

      context "when the hook filters apply to individual examples instead of example groups" do
        let(:each_filters) { [] }
        let(:all_filters) { [] }

        let(:example_group) do
          md = example_metadata
          RSpec.describe do
            it("example", md) { }
          end
        end

        def filters
          each_filters + all_filters
        end

        before(:each) do
          af, ef = all_filters, each_filters

          RSpec.configure do |c|
            c.before(:all,  :foo => :bar) { af << "before all in config"}
            c.around(:each, :foo => :bar) {|example| ef << "around each in config"; example.run}
            c.before(:each, :foo => :bar) { ef << "before each in config"}
            c.after(:each,  :foo => :bar) { ef << "after each in config"}
            c.after(:all,   :foo => :bar) { af << "after all in config"}
          end

          example_group.run
        end

        describe 'an example with matching metadata' do
          let(:example_metadata) { { :foo => :bar } }

          it "runs the `:each` hooks" do
            expect(each_filters).to eq([
              'around each in config',
              'before each in config',
              'after each in config'
            ])
          end
        end

        describe 'an example without matching metadata' do
          let(:example_metadata) { { :foo => :bazz } }

          it "does not run any of the hooks" do
            expect(self.filters).to be_empty
          end
        end
      end
    end

    describe "hooks with multiple filters" do
      it "is run if all hook filters match the group's filters" do
        filters = []
        RSpec.configure do |c|
          c.before(:all,  :one => 1)                         { filters << "before all in config"}
          c.around(:each, :two => 2, :one => 1)              {|example| filters << "around each in config"; example.run}
          c.before(:each, :one => 1, :two => 2)              { filters << "before each in config"}
          c.after(:each,  :one => 1, :two => 2, :three => 3) { filters << "after each in config"}
          c.after(:all,   :one => 1, :three => 3)            { filters << "after all in config"}
        end
        group = RSpec.describe("group", :one => 1, :two => 2, :three => 3)
        group.example("example") {}
        group.run
        expect(filters).to eq([
          "before all in config",
          "around each in config",
          "before each in config",
          "after each in config",
          "after all in config"
        ])
      end

      it "does not run if some hook filters don't match the group's filters" do
        sequence = []

        RSpec.configure do |c|
          c.before(:all,  :one => 1, :four => 4)                         { sequence << "before all in config"}
          c.around(:each, :two => 2, :four => 4)                         {|example| sequence << "around each in config"; example.run}
          c.before(:each, :one => 1, :two => 2, :four => 4)              { sequence << "before each in config"}
          c.after(:each,  :one => 1, :two => 2, :three => 3, :four => 4) { sequence << "after each in config"}
          c.after(:all,   :one => 1, :three => 3, :four => 4)            { sequence << "after all in config"}
        end

        RSpec.describe "group", :one => 1, :two => 2, :three => 3 do
          example("ex1") { sequence << "ex1" }
          example("ex2", :four => 4) { sequence << "ex2" }
        end.run

        expect(sequence).to eq([
          "ex1",
          "before all in config",
          "around each in config",
          "before each in config",
          "ex2",
          "after each in config",
          "after all in config"
        ])
      end

      it "does not run for examples that do not match, even if their group matches" do
        filters = []

        RSpec.configure do |c|
          c.before(:each, :apply_it) { filters << :before_each }
        end

        RSpec.describe "Group", :apply_it do
          example("ex1") { filters << :matching_example }
          example("ex2", :apply_it => false) { filters << :nonmatching_example }
        end.run

        expect(filters).to eq([:before_each, :matching_example, :nonmatching_example])
      end
    end

    describe ":context hooks defined in configuration with metadata" do
      it 'applies to individual matching examples' do
        sequence = []

        RSpec.configure do |config|
          config.before(:context, :apply_it) { sequence << :before_context }
          config.after(:context, :apply_it)  { sequence << :after_context  }
        end

        RSpec.describe do
          example("ex", :apply_it) { sequence << :example }
        end.run

        expect(sequence).to eq([:before_context, :example, :after_context])
      end

      it 'does not apply to individual matching examples for which it also applies to a parent example group' do
        sequence = []

        RSpec.configure do |config|
          config.before(:context, :apply_it) { sequence << :before_context }
          config.after(:context, :apply_it)  { sequence << :after_context  }
        end

        RSpec.describe "Group", :apply_it do
          example("ex") { sequence << :outer_example }

          context "nested", :apply_it => false do
            example("ex", :apply_it) { sequence << :inner_example }
          end
        end.run

        expect(sequence).to eq([:before_context, :outer_example, :inner_example, :after_context])
      end
    end
  end
end
