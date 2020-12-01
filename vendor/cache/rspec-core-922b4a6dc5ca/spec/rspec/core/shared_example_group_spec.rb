require 'rspec/support/spec/in_sub_process'

module RandomTopLevelModule
  def self.setup!
    RSpec.shared_examples_for("top level in module") {}
  end
end

module RSpec
  module Core
    RSpec.describe SharedExampleGroup do
      include RSpec::Support::InSubProcess
      let(:registry) { RSpec.world.shared_example_group_registry }

      ExampleModule = Module.new
      ExampleClass  = Class.new

      it 'does not add a bunch of private methods to Module' do
        seg_methods = RSpec::Core::SharedExampleGroup.private_instance_methods
        expect(Module.private_methods & seg_methods).to eq([])
      end

      before do
        # this is a work around as SharedExampleGroup is not world safe
        RandomTopLevelModule.setup!
      end

      RSpec::Matchers.define :have_example_descriptions do |*descriptions|
        match do |example_group|
          example_group.examples.map(&:description) == descriptions
        end

        failure_message do |example_group|
          actual = example_group.examples.map(&:description)
          "expected #{example_group.name} to have descriptions: #{descriptions.inspect} but had #{actual.inspect}"
        end
      end

      %w[shared_examples shared_examples_for shared_context].each do |shared_method_name|
        describe shared_method_name do
          let(:group) { RSpec.describe('example group') }

          before do
            RSpec.configuration.shared_context_metadata_behavior = :apply_to_host_groups
          end

          define_method :define_shared_group do |*args, &block|
            group.send(shared_method_name, *args, &block)
          end

          define_method :define_top_level_shared_group do |*args, &block|
            RSpec.send(shared_method_name, *args, &block)
          end

          def find_implementation_block(registry, scope, name)
            registry.find([scope], name).definition
          end

          it "is exposed to the global namespace when expose_dsl_globally is enabled" do
            in_sub_process do
              RSpec.configuration.expose_dsl_globally = true
              expect(Kernel).to respond_to(shared_method_name)
            end
          end

          it "is not exposed to the global namespace when monkey patching is disabled" do
            RSpec.configuration.expose_dsl_globally = false
            expect(RSpec.configuration.expose_dsl_globally?).to eq(false)
            expect(Kernel).to_not respond_to(shared_method_name)
          end

          # These keyword specs cover all 4 of the keyword / keyword like syntax varients
          # they should be warning free.

          if RSpec::Support::RubyFeatures.required_kw_args_supported?
            it 'supports required keyword arguments' do
              binding.eval(<<-CODE, __FILE__, __LINE__)
              group.__send__ shared_method_name, "shared context expects keywords" do |foo:|
                it "has an expected value" do
                  expect(foo).to eq("bar")
                end
              end

              group.__send__ shared_method_name, "shared context expects hash" do |a_hash|
                it "has an expected value" do
                  expect(a_hash[:foo]).to eq("bar")
                end
              end

              group.it_behaves_like "shared context expects keywords", foo: "bar"
              group.it_behaves_like "shared context expects keywords", { foo: "bar" }

              group.it_behaves_like "shared context expects hash", foo: "bar"
              group.it_behaves_like "shared context expects hash", { foo: "bar" }
              CODE
              expect(group.run).to eq true
            end
          end

          if RSpec::Support::RubyFeatures.kw_args_supported?
            it 'supports optional keyword arguments' do
              binding.eval(<<-CODE, __FILE__, __LINE__)
              group.__send__ shared_method_name, "shared context expects keywords" do |foo: nil|
                it "has an expected value" do
                  expect(foo).to eq("bar")
                end
              end

              group.__send__ shared_method_name, "shared context expects hash" do |a_hash|
                it "has an expected value" do
                  expect(a_hash[:foo]).to eq("bar")
                end
              end

              group.it_behaves_like "shared context expects keywords", foo: "bar"
              group.it_behaves_like "shared context expects keywords", { foo: "bar" }

              group.it_behaves_like "shared context expects hash", foo: "bar"
              group.it_behaves_like "shared context expects hash", { foo: "bar" }
              CODE
              expect(group.run).to eq true
            end
          end

          it "displays a warning when adding an example group without a block", :unless => RUBY_VERSION == '1.8.7' do
            expect_warning_with_call_site(__FILE__, __LINE__ + 1)
            group.send(shared_method_name, 'name but no block')
          end

          it "displays a warning when adding an example group without a block", :if => RUBY_VERSION == '1.8.7' do
            # In 1.8.7 this spec breaks unless we run it isolated like this
            in_sub_process do
              expect_warning_with_call_site(__FILE__, __LINE__ + 1)
              group.send(shared_method_name, 'name but no block')
            end
          end

          it 'displays a warning when adding a second shared example group with the same name' do
            group.send(shared_method_name, 'some shared group') {}
            original_declaration = [__FILE__, __LINE__ - 1].join(':')

            warning = nil
            allow(::Kernel).to receive(:warn) { |msg| warning = msg }

            group.send(shared_method_name, 'some shared group') {}
            second_declaration = [__FILE__, __LINE__ - 1].join(':')
            expect(warning).to include('some shared group', original_declaration, second_declaration)
            expect(warning).to_not include 'Called from'
          end

          it 'displays a helpful message when you define a shared example group in *_spec.rb file' do
            warning = nil
            allow(::Kernel).to receive(:warn) { |msg| warning = msg }
            declaration = nil

            2.times do
              group.send(shared_method_name, 'some shared group') {}
              declaration = [__FILE__, __LINE__ - 1].join(':')
              RSpec.configuration.loaded_spec_files << declaration
            end

            better_error = 'was automatically loaded by RSpec because the file name'
            expect(warning).to include('some shared group', declaration, better_error)
            expect(warning).to_not include 'Called from'
          end

          it 'works with top level defined examples in modules' do
            expect(RSpec::configuration.reporter).to_not receive(:deprecation)
            RSpec.describe('example group') { include_context 'top level in module' }
          end

          it 'generates a named (rather than anonymous) module' do
            define_top_level_shared_group("shared behaviors") { }
            RSpec.configuration.include_context "shared behaviors", :include_it
            example_group = RSpec.describe("Group", :include_it) { }

            anonymous_module_regex = /#<Module:0x[0-9a-f]+>/
            expect(Module.new.inspect).to match(anonymous_module_regex)

            include_a_named_rather_than_anonymous_module = (
              include(a_string_including(
                "#<RSpec::Core::SharedExampleGroupModule", "shared behaviors"
              )).and exclude(a_string_matching(anonymous_module_regex))
            )

            expect(example_group.ancestors.map(&:inspect)).to include_a_named_rather_than_anonymous_module
            expect(example_group.ancestors.map(&:to_s)).to include_a_named_rather_than_anonymous_module
          end

          ["name", :name, ExampleModule, ExampleClass].each do |object|
            type = object.class.name.downcase
            context "given a #{type}" do
              it "captures the given #{type} and block in the collection of shared example groups" do
                implementation = lambda { }
                define_shared_group(object, &implementation)
                expect(find_implementation_block(registry, group, object)).to eq implementation
              end
            end
          end

          context "when `config.shared_context_metadata_behavior == :trigger_inclusion`" do
            before do
              RSpec.configuration.shared_context_metadata_behavior = :trigger_inclusion
            end

            context "given a hash" do
              it "includes itself in matching example groups" do
                implementation = Proc.new { def self.bar; 'bar'; end }
                define_shared_group(:foo => :bar, &implementation)

                matching_group = RSpec.describe "Group", :foo => :bar
                non_matching_group = RSpec.describe "Group"

                expect(matching_group.bar).to eq("bar")
                expect(non_matching_group).not_to respond_to(:bar)
              end
            end

            context "given a string and a hash" do
              it "captures the given string and block in the World's collection of shared example groups" do
                implementation = lambda { }
                define_shared_group("name", :foo => :bar, &implementation)
                expect(find_implementation_block(registry, group, "name")).to eq implementation
              end

              it "delegates include on configuration" do
                implementation = Proc.new { def self.bar; 'bar'; end }
                define_shared_group("name", :foo => :bar, &implementation)

                matching_group = RSpec.describe "Group", :foo => :bar
                non_matching_group = RSpec.describe "Group"

                expect(matching_group.bar).to eq("bar")
                expect(non_matching_group).not_to respond_to(:bar)
              end
            end

            it "displays a warning when adding a second shared example group with the same name" do
              group.send(shared_method_name, 'some shared group') {}
              original_declaration = [__FILE__, __LINE__ - 1].join(':')

              warning = nil
              allow(::Kernel).to receive(:warn) { |msg| warning = msg }

              group.send(shared_method_name, 'some shared group') {}
              second_declaration = [__FILE__, __LINE__ - 1].join(':')
              expect(warning).to include('some shared group', original_declaration, second_declaration)
              expect(warning).to_not include 'Called from'
            end
          end

          context "when `config.shared_context_metadata_behavior == :apply_to_host_groups`" do
            before do
              RSpec.configuration.shared_context_metadata_behavior = :apply_to_host_groups
            end

            it "does not auto-include the shared group based on passed metadata" do
              define_top_level_shared_group("name", :foo => :bar) do
                def self.bar; 'bar'; end
              end

              matching_group = RSpec.describe "Group", :foo => :bar

              expect(matching_group).not_to respond_to(:bar)
            end

            it "adds passed metadata to including groups and examples" do
              define_top_level_shared_group("name", :foo => :bar) { }

              group = RSpec.describe("outer")
              nested = group.describe("inner")
              example = group.example("ex")

              group.include_context "name"

              expect([group, nested, example]).to all have_attributes(
                :metadata => a_hash_including(:foo => :bar)
              )
            end

            it "requires a valid name" do
              expect {
                define_shared_group(:foo => 1) { }
              }.to raise_error(ArgumentError, a_string_including(
                "Shared example group names",
                {:foo => 1}.inspect
              ))
            end

            it "does not overwrite existing metadata values set at that level when included via `include_context`" do
              shared_ex_metadata = nil
              host_ex_metadata = nil

              define_top_level_shared_group("name", :foo => :shared) do
                it { |ex| shared_ex_metadata = ex.metadata }
              end

              describe_successfully("Group", :foo => :host) do
                include_context "name"
                it { |ex| host_ex_metadata = ex.metadata }
              end

              expect(host_ex_metadata[:foo]).to eq :host
              expect(shared_ex_metadata[:foo]).to eq :host
            end

            it "overwrites existing metadata values set at a parent level when included via `include_context`" do
              shared_ex_metadata = nil
              host_ex_metadata = nil

              define_top_level_shared_group("name", :foo => :shared) do
                it { |ex| shared_ex_metadata = ex.metadata }
              end

              describe_successfully("Group", :foo => :host) do
                context "nested" do
                  include_context "name"
                  it { |ex| host_ex_metadata = ex.metadata }
                end
              end

              expect(host_ex_metadata[:foo]).to eq :shared
              expect(shared_ex_metadata[:foo]).to eq :shared
            end

            it "propagates conflicted metadata to examples defined in the shared group when included via `it_behaves_like` since it makes a nested group" do
              shared_ex_metadata = nil
              host_ex_metadata = nil

              define_top_level_shared_group("name", :foo => :shared) do
                it { |ex| shared_ex_metadata = ex.metadata }
              end

              describe_successfully("Group", :foo => :host) do
                it_behaves_like "name"
                it { |ex| host_ex_metadata = ex.metadata }
              end

              expect(host_ex_metadata[:foo]).to eq :host
              expect(shared_ex_metadata[:foo]).to eq :shared
            end

            it "applies metadata from the shared group to the including group, when the shared group itself is loaded and included via metadata" do
              RSpec.configure do |config|
                config.when_first_matching_example_defined(:controller) do
                  define_top_level_shared_group("controller support", :capture_logging) { }

                  config.include_context "controller support", :controller
                end
              end

              group = RSpec.describe("group", :controller)
              ex = group.it

              expect(ex.metadata).to include(:controller => true, :capture_logging => true)
            end
          end

          context "when the group is included via `config.include_context` and matching metadata" do
            before do
              # To ensure we don't accidentally include shared contexts the
              # old way in this context, we disable the option here.
              RSpec.configuration.shared_context_metadata_behavior = :apply_to_host_groups
            end

            describe "when it has a `let` and applies to an individual example via metadata" do
              it 'defines the `let` method correctly' do
                define_top_level_shared_group("name") do
                  let(:foo) { "bar" }
                end
                RSpec.configuration.include_context "name", :include_it

                ex = value = nil
                RSpec.describe "group" do
                  ex = example("ex1", :include_it) { value = foo }
                end.run

                expect(ex.execution_result).to have_attributes(:status => :passed, :exception => nil)
                expect(value).to eq("bar")
              end
            end

            describe "hooks for individual examples that have matching metadata" do
              before do
                skip "These specs pass in 2.0 mode on JRuby 1.7.8 but fail on " \
                     "1.7.15 when the entire spec suite runs. They pass on " \
                     "1.7.15 when this one spec file is run or if we filter to " \
                     "just them. Given that 2.0 support on JRuby 1.7 is " \
                     "experimental, we're just skipping these specs."
              end if RUBY_VERSION == "2.0.0" && RSpec::Support::Ruby.jruby?

              it 'runs them' do
                sequence = []

                define_top_level_shared_group("name") do
                  before(:context) { sequence << :before_context }
                  after(:context)  { sequence << :after_context }

                  before(:example) { sequence << :before_example }
                  after(:example)  { sequence << :after_example  }

                  around(:example) do |ex|
                    sequence << :around_example_before
                    ex.run
                    sequence << :around_example_after
                  end
                end

                RSpec.configuration.include_context "name", :include_it

                RSpec.describe "group" do
                  example("ex1") { sequence << :unmatched_example_1 }
                  example("ex2", :include_it) { sequence << :matched_example }
                  example("ex3") { sequence << :unmatched_example_2 }
                end.run

                expect(sequence).to eq([
                  :unmatched_example_1,
                  :before_context,
                  :around_example_before,
                  :before_example,
                  :matched_example,
                  :after_example,
                  :around_example_after,
                  :after_context,
                  :unmatched_example_2
                ])
              end

              it 'runs the `after(:context)` hooks even if the `before(:context)` hook raises an error' do
                sequence = []

                define_top_level_shared_group("name") do
                  before(:context) do
                    sequence << :before_context
                    raise "boom"
                  end
                  after(:context) { sequence << :after_context }
                end

                RSpec.configuration.include_context "name", :include_it

                RSpec.describe "group" do
                  example("ex", :include_it) { sequence << :example }
                end.run

                expect(sequence).to eq([ :before_context, :after_context ])
              end
            end
          end

          context "when called at the top level" do
            before do
              RSpec.__send__(shared_method_name, "shared context") do
                example "shared spec"
              end
            end

            it 'is available for inclusion from a top level group' do
              group = RSpec.describe "group" do
                include_examples "shared context"
              end

              expect(group).to have_example_descriptions("shared spec")
            end

            it 'is available for inclusion from a nested example group' do
              group = nil

              RSpec.describe "parent" do
                context "child" do
                  group = context("grand child") { include_examples "shared context" }
                end
              end

              expect(group).to have_example_descriptions("shared spec")
            end

            it 'is trumped by a shared group with the same name that is defined in the including context' do
              group = RSpec.describe "parent" do
                __send__ shared_method_name, "shared context" do
                  example "a different spec"
                end

                include_examples "shared context"
              end

              expect(group).to have_example_descriptions("a different spec")
            end

            it 'is trumped by a shared group with the same name that is defined in a parent group' do
              group = nil

              RSpec.describe "parent" do
                __send__ shared_method_name, "shared context" do
                  example "a different spec"
                end

                group = context("nested") { include_examples "shared context" }
              end

              expect(group).to have_example_descriptions("a different spec")
            end
          end

          context "when called from within an example group" do
            define_method :in_group_with_shared_group_def do |&block|
              RSpec.describe "an example group" do
                __send__ shared_method_name, "shared context" do
                  example "shared spec"
                end

                module_exec(&block)
              end
            end

            it 'is available for inclusion within that group' do
              group = in_group_with_shared_group_def do
                include_examples "shared context"
              end

              expect(group).to have_example_descriptions("shared spec")
            end

            it 'is available for inclusion in a child group' do
              group = nil

              in_group_with_shared_group_def do
                group = context("nested") { include_examples "shared context" }
              end

              expect(group).to have_example_descriptions("shared spec")
            end

            it 'is not available for inclusion in a different top level group' do
              in_group_with_shared_group_def { }

              expect {
                RSpec.describe "another top level group" do
                  include_examples "shared context"
                end
              }.to raise_error(/Could not find/)
            end

            it 'is not available for inclusion in a nested group of a different top level group' do
              in_group_with_shared_group_def { }

              expect {
                RSpec.describe "another top level group" do
                  context("nested") { include_examples "shared context" }
                end
              }.to raise_error(/Could not find/)
            end

            it 'trumps a shared group with the same name defined at the top level' do
              RSpec.__send__(shared_method_name, "shared context") do
                example "a different spec"
              end

              group = in_group_with_shared_group_def do
                include_examples "shared context"
              end

              expect(group).to have_example_descriptions("shared spec")
            end

            it 'is trumped by a shared group with the same name that is defined in the including context' do
              group = nil

              in_group_with_shared_group_def do
                group = context "child" do
                  __send__ shared_method_name, "shared context" do
                    example "a different spec"
                  end

                  include_examples "shared context"
                end
              end

              expect(group).to have_example_descriptions("a different spec")
            end

            it 'is trumped by a shared group with the same name that is defined in nearer parent group' do
              group = nil

              in_group_with_shared_group_def do
                context "child" do
                  __send__ shared_method_name, "shared context" do
                    example "a different spec"
                  end

                  group = context("grandchild") { include_examples "shared context" }
                end
              end

              expect(group).to have_example_descriptions("a different spec")
            end
          end
        end
      end
    end
  end
end
