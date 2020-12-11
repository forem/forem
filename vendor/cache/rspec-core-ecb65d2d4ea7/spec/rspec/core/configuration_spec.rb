require 'tmpdir'
require 'rspec/support/spec/in_sub_process'

module RSpec::Core
  RSpec.describe Configuration do
    include RSpec::Support::InSubProcess

    let(:config) { Configuration.new }
    let(:exclusion_filter) { config.exclusion_filter.rules }
    let(:inclusion_filter) { config.inclusion_filter.rules }

    before { config.world = RSpec.world }

    shared_examples_for "warning of deprecated `:example_group` during filtering configuration" do |method, *args|
      it "issues a deprecation warning when filtering by `:example_group`" do
        args << { :example_group => { :file_location => /spec\/unit/ } }
        expect_deprecation_with_call_site(__FILE__, __LINE__ + 1, /:example_group/)
        config.__send__(method, *args)
      end
    end

    describe '#on_example_group_definition' do
      before do
        RSpec.configure do |c|
          c.on_example_group_definition do |example_group|
            example_group.examples.first.metadata[:new_key] = :new_value
          end
        end
      end

      it 'successfully invokes the block' do
        RSpec.describe("group") { it "example 1" do; end}
        example = RSpec.world.example_groups.first.examples.first
        expect(example.metadata[:new_key]).to eq(:new_value)
      end
    end

    describe "#fail_fast" do
      it "defaults to `nil`" do
        expect(RSpec::Core::Configuration.new.fail_fast).to be(nil)
      end
    end

    describe "#fail_fast=" do
      context 'when true' do
        it 'is set to true' do
          config.fail_fast = true
          expect(config.fail_fast).to eq true
        end
      end

      context "when 'true'" do
        it 'is set to true' do
          config.fail_fast = 'true'
          expect(config.fail_fast).to eq true
        end
      end

      context "when false" do
        it 'is set to false' do
          config.fail_fast = false
          expect(config.fail_fast).to eq false
        end
      end

      context "when 'false'" do
        it 'is set to false' do
          config.fail_fast = 'false'
          expect(config.fail_fast).to eq false
        end
      end

      context "when 0" do
        it 'is set to false' do
          config.fail_fast = 0
          expect(config.fail_fast).to eq false
        end
      end

      context "when integer number" do
        it 'is set to number' do
          config.fail_fast = 5
          expect(config.fail_fast).to eq 5
        end
      end

      context "when floating point number" do
        it 'is set to integer number' do
          config.fail_fast = 5.9
          expect(config.fail_fast).to eq 5
        end
      end

      context "when string represeting an integer number" do
        it 'is set to number' do
          config.fail_fast = '5'
          expect(config.fail_fast).to eq 5
        end
      end

      context "when nil" do
        it 'is nil' do
          config.fail_fast = nil
          expect(config.fail_fast).to eq nil
        end
      end

      context "when unrecognized value" do
        before do
          allow(RSpec).to receive(:warning)
        end

        it 'prints warning' do
          config.fail_fast = 'yes'
          expect(RSpec).to have_received(:warning).with(/Cannot set `RSpec.configuration.fail_fast`/i)
        end

        it 'is set to true' do
          config.fail_fast = 'yes'
          expect(config.fail_fast).to eq true
        end
      end
    end

    describe 'fail_if_no_examples' do
      it 'defaults to false' do
        expect(RSpec::Core::Configuration.new.fail_if_no_examples).to be(false)
      end

      it 'can be set to true' do
        config.fail_if_no_examples = true
        expect(config.fail_if_no_examples).to eq(true)
      end

      it 'can be set to false' do
        config.fail_if_no_examples = false
        expect(config.fail_if_no_examples).to eq(false)
      end
    end

    describe '#deprecation_stream' do
      it 'defaults to standard error' do
        expect($rspec_core_without_stderr_monkey_patch.deprecation_stream).to eq STDERR
      end

      it 'is configurable' do
        io = StringIO.new
        config.deprecation_stream = io
        expect(config.deprecation_stream).to eq io
      end

      context 'when the reporter has already been initialized' do
        before do
          config.reporter
          allow(config).to receive(:warn)
        end

        it 'prints a notice indicating the reconfigured output_stream will be ignored' do
          config.deprecation_stream = double("IO")
          expect(config).to have_received(:warn).with(/deprecation_stream.*#{__FILE__}:#{__LINE__ - 1}/)
        end

        it 'does not change the value of `deprecation_stream`' do
          value = config.deprecation_stream
          config.deprecation_stream = double("IO")
          expect(config.deprecation_stream).to equal(value)
        end

        it 'does not print a warning if set to the value it already has' do
          config.deprecation_stream = config.deprecation_stream
          expect(config).not_to have_received(:warn)
        end
      end
    end

    describe "#output_stream" do
      it 'defaults to standard output' do
        expect(config.output_stream).to eq $stdout
      end
    end

    describe "#output_stream=" do
      it 'is configurable' do
        io = StringIO.new
        config.output_stream = io
        expect(config.output_stream).to eq io
      end

      context 'when the reporter has already been initialized' do
        before do
          config.reporter
          allow(config).to receive(:warn)
        end

        it 'prints a notice indicating the reconfigured output_stream will be ignored' do
          config.output_stream = StringIO.new
          expect(config).to have_received(:warn).with(/output_stream.*#{__FILE__}:#{__LINE__ - 1}/)
        end

        it 'does not change the value of `output_stream`' do
          config.output_stream = StringIO.new
          expect(config.output_stream).to eq($stdout)
        end

        it 'does not print a warning if set to the value it already has' do
          config.output_stream = config.output_stream
          expect(config).not_to have_received(:warn)
        end
      end
    end

    describe "#requires=" do
      def absolute_path_to(dir)
        File.expand_path("../../../../#{dir}", __FILE__)
      end

      it 'adds `lib` to the load path' do
        lib_dir = absolute_path_to("lib")
        $LOAD_PATH.delete(lib_dir)

        expect($LOAD_PATH).not_to include(lib_dir)
        config.requires = []
        expect($LOAD_PATH).to include(lib_dir)
      end

      it 'adds the configured `default_path` to the load path' do
        config.default_path = 'features'
        foo_dir = absolute_path_to("features")

        expect($LOAD_PATH).not_to include(foo_dir)
        config.requires = []
        expect($LOAD_PATH).to include(foo_dir)
      end

      it 'stores the required files' do
        expect(config).to receive(:require).with('a/path')
        config.requires = ['a/path']
        expect(config.requires).to eq ['a/path']
      end

      context "when `default_path` refers to a file rather than a directory" do
        it 'does not add it to the load path' do
          config.default_path = 'Rakefile'
          config.requires = []
          expect($LOAD_PATH).not_to include(match(/Rakefile/))
        end
      end
    end

    describe "#load_spec_files" do
      it "loads files using load" do
        config.files_to_run = ["foo.bar", "blah_spec.rb"]
        expect(config).to receive(:load).twice
        config.load_spec_files
      end

      it "loads each file once, even if duplicated in list" do
        config.files_to_run = ["a_spec.rb", "a_spec.rb"]
        expect(config).to receive(:load).once
        config.load_spec_files
      end
    end

    describe "#mock_framework" do
      it "defaults to :rspec" do
        expect(RSpec::Support).to receive(:require_rspec_core).with('mocking_adapters/rspec')
        expect(config.mock_framework).to eq(MockingAdapters::RSpec)
      end

      context "when rspec-mocks is not installed" do
        it 'gracefully falls back to :nothing' do
          allow(RSpec::Support).to receive(:require_rspec_core).and_call_original
          allow(RSpec::Support).to receive(:require_rspec_core).with('mocking_adapters/rspec').and_raise(LoadError)

          expect(config.mock_framework).to eq(MockingAdapters::Null)
        end
      end
    end

    describe "#mock_framework="do
      it "delegates to mock_with" do
        expect(config).to receive(:mock_with).with(:rspec)
        config.mock_framework = :rspec
      end
    end

    shared_examples "a configurable framework adapter" do |m|
      it "yields a config object if the framework_module supports it" do
        mod = Module.new
        def mod.configuration; @config ||= Struct.new(:custom_setting).new; end

        config.send m, mod do |mod_config|
          mod_config.custom_setting = true
        end

        expect(mod.configuration.custom_setting).to be(true)
      end

      it "raises if framework module doesn't support configuration" do
        mod = Module.new

        expect {
          config.send m, mod do |mod_config|
          end
        }.to raise_error(/must respond to `configuration`/)
      end
    end

    describe "#mock_with" do
      before { allow(config).to receive(:require) }

      it_behaves_like "a configurable framework adapter", :mock_with

      it "allows rspec-mocks to be configured with a provided block" do
        mod = Module.new

        expect(RSpec::Mocks.configuration).to receive(:add_stub_and_should_receive_to).with(mod)

        config.mock_with :rspec do |c|
          c.add_stub_and_should_receive_to mod
        end
      end

      context "with a module" do
        it "sets the mock_framework_adapter to that module" do
          mod = Module.new
          config.mock_with mod
          expect(config.mock_framework).to eq(mod)
        end
      end

      it 'uses the named adapter' do
        expect(RSpec::Support).to receive(:require_rspec_core).with('mocking_adapters/mocha')
        stub_const("RSpec::Core::MockingAdapters::Mocha", Module.new)
        config.mock_with :mocha
      end

      it "uses the null adapter when given :nothing" do
        expect(RSpec::Support).to receive(:require_rspec_core).with('mocking_adapters/null').and_call_original
        config.mock_with :nothing
      end

      it "raises an error when given an unknown key" do
        expect {
          config.mock_with :crazy_new_mocking_framework_ive_not_yet_heard_of
        }.to raise_error(ArgumentError, /unknown mocking framework/i)
      end

      it "raises an error when given another type of object" do
        expect {
          config.mock_with Object.new
        }.to raise_error(ArgumentError, /unknown mocking framework/i)
      end

      context 'when there are already some example groups defined' do
        before { allow(RSpec::Support).to receive(:require_rspec_core) }

        it 'raises an error since this setting must be applied before any groups are defined' do
          allow(RSpec.world).to receive(:example_groups).and_return([double.as_null_object])
          class_double("RSpec::Core::MockingAdapters::Mocha", :framework_name => :mocha).as_stubbed_const

          expect {
            config.mock_with :mocha
          }.to raise_error(/must be configured before any example groups are defined/)
        end

        it 'does not raise an error if the default `mock_with :rspec` is re-configured' do
          config.mock_framework # called by RSpec when configuring the first example group
          allow(RSpec.world).to receive(:example_groups).and_return([double.as_null_object])
          config.mock_with :rspec
        end

        it 'does not raise an error if re-setting the same config' do
          class_double("RSpec::Core::MockingAdapters::Mocha", :framework_name => :mocha).as_stubbed_const

          groups = []
          allow(RSpec.world).to receive_messages(:example_groups => groups)
          config.mock_with :mocha
          groups << double.as_null_object
          config.mock_with :mocha
        end
      end
    end

    describe "#expectation_frameworks" do
      it "defaults to :rspec" do
        expect(config).to receive(:require).with('rspec/expectations')
        expect(config.expectation_frameworks).to eq([RSpec::Matchers])
      end

      context "when rspec-expectations is not installed" do
        def an_anonymous_module
          name = RUBY_VERSION.to_f < 1.9 ? '' : nil
          an_object_having_attributes(:class => Module, :name => name)
        end

        it 'gracefully falls back to an anonymous module' do
          allow(config).to receive(:require).with('rspec/expectations').and_raise(LoadError)
          expect(config.expectation_frameworks).to match([an_anonymous_module])
        end
      end
    end

    describe "#expectation_framework=" do
      it "delegates to expect_with" do
        expect(config).to receive(:expect_with).with(:rspec)
        config.expectation_framework = :rspec
      end
    end

    def stub_expectation_adapters
      stub_const("Test::Unit::Assertions", Module.new)
      stub_const("Minitest::Assertions", Module.new)
      stub_const("RSpec::Core::TestUnitAssertionsAdapter", Module.new)
      stub_const("RSpec::Core::MinitestAssertionsAdapter", Module.new)
      allow(config).to receive(:require)
    end

    describe "#expect_with" do
      before do
        stub_expectation_adapters
      end

      it_behaves_like "a configurable framework adapter", :expect_with

      context "with :rspec" do
        it "requires rspec/expectations" do
          expect(config).to receive(:require).with('rspec/expectations')
          config.expect_with :rspec
        end

        it "sets the expectation framework to ::RSpec::Matchers" do
          config.expect_with :rspec
          expect(config.expectation_frameworks).to eq [::RSpec::Matchers]
        end
      end

      context "with :test_unit" do
        it "requires rspec/core/test_unit_assertions_adapter" do
          expect(config).to receive(:require).
            with('rspec/core/test_unit_assertions_adapter')
          config.expect_with :test_unit
        end

        it "sets the expectation framework to ::Test::Unit::Assertions" do
          config.expect_with :test_unit
          expect(config.expectation_frameworks).to eq [
            ::RSpec::Core::TestUnitAssertionsAdapter
          ]
        end
      end

      context "with :minitest" do
        it "requires rspec/core/minitest_assertions_adapter" do
          expect(config).to receive(:require).
            with('rspec/core/minitest_assertions_adapter')
          config.expect_with :minitest
        end

        it "sets the expectation framework to ::Minitest::Assertions" do
          config.expect_with :minitest
          expect(config.expectation_frameworks).to eq [
            ::RSpec::Core::MinitestAssertionsAdapter
          ]
        end
      end

      it "supports multiple calls" do
        config.expect_with :rspec
        config.expect_with :minitest
        expect(config.expectation_frameworks).to eq [
          RSpec::Matchers,
          RSpec::Core::MinitestAssertionsAdapter
        ]
      end

      it "raises if block given with multiple args" do
        expect {
          config.expect_with :rspec, :minitest do |mod_config|
          end
        }.to raise_error(/expect_with only accepts/)
      end

      it "raises ArgumentError if framework is not supported" do
        expect do
          config.expect_with :not_supported
        end.to raise_error(ArgumentError)
      end

      context 'when there are already some example groups defined' do
        it 'raises an error since this setting must be applied before any groups are defined' do
          allow(RSpec.world).to receive(:example_groups).and_return([double.as_null_object])
          expect {
            config.expect_with :rspec
          }.to raise_error(/must be configured before any example groups are defined/)
        end

        it 'does not raise an error if the default `expect_with :rspec` is re-configured' do
          config.expectation_frameworks # called by RSpec when configuring the first example group
          allow(RSpec.world).to receive(:example_groups).and_return([double.as_null_object])
          config.expect_with :rspec
        end

        it 'does not raise an error if re-setting the same config' do
          groups = []
          allow(RSpec.world).to receive_messages(:example_groups => groups)
          config.expect_with :minitest
          groups << double.as_null_object
          config.expect_with :minitest
        end
      end
    end

    describe "#files_to_run" do
      it "loads files not following pattern if named explicitly" do
        assign_files_or_directories_to_run "spec/rspec/core/resources/a_bar.rb"
        expect(config.files_to_run).to contain_files("spec/rspec/core/resources/a_bar.rb")
      end

      it "prevents repetition of dir when start of the pattern" do
        config.pattern = "spec/**/a_spec.rb"
        assign_files_or_directories_to_run "spec"
        expect(config.files_to_run).to contain_files("spec/rspec/core/resources/a_spec.rb")
      end

      it "does not prevent repetition of dir when later of the pattern" do
        config.pattern = "rspec/**/a_spec.rb"
        assign_files_or_directories_to_run "spec"
        expect(config.files_to_run).to contain_files("spec/rspec/core/resources/a_spec.rb")
      end

      it "supports patterns starting with ./" do
        config.pattern = "./spec/**/a_spec.rb"
        assign_files_or_directories_to_run "spec"
        expect(config.files_to_run).to contain_files("./spec/rspec/core/resources/a_spec.rb")
      end

      it "supports absolute path patterns", :emits_warning_on_windows_on_old_ruby do
        dir = File.expand_path("../resources", __FILE__)
        config.pattern = File.join(dir, "**/*_spec.rb")
        assign_files_or_directories_to_run "spec"

        expect(config.files_to_run).to contain_files(
          "./spec/rspec/core/resources/acceptance/foo_spec.rb",
          "./spec/rspec/core/resources/a_spec.rb"
        )
      end

      it "supports relative path patterns for an alternate directory from `spec`" do
        Dir.chdir("./spec/rspec/core") do
          config.pattern = "resources/**/*_spec.rb"
          assign_files_or_directories_to_run "spec" # default dir

          expect(config.files_to_run).to contain_files(
            "resources/acceptance/foo_spec.rb",
            "resources/a_spec.rb"
          )
        end
      end

      it "does not attempt to treat the pattern relative to `.` if it uses `**` in the first path segment as that would cause it load specs from vendored gems" do
        Dir.chdir("./spec/rspec/core") do
          config.pattern = "**/*_spec.rb"
          assign_files_or_directories_to_run "spec" # default dir

          expect(config.files_to_run).to contain_files()
        end
      end

      it 'reloads when `files_or_directories_to_run` is reassigned' do
        config.pattern = "spec/**/a_spec.rb"
        config.files_or_directories_to_run = "empty_dir"

        expect {
          config.files_or_directories_to_run = "spec"
        }.to change { config.files_to_run }.
          to(a_file_collection("spec/rspec/core/resources/a_spec.rb"))
      end

      it 'attempts to load the provided file names' do
        assign_files_or_directories_to_run "path/to/some/file.rb"
        expect(config.files_to_run).to contain_files("path/to/some/file.rb")
      end

      it 'does not attempt to load a file at the `default_path`' do
        config.default_path = "path/to/dir"
        assign_files_or_directories_to_run "path/to/dir"
        expect(config.files_to_run).to eq([])
      end

      context "with <path>:<line_number>" do
        it "overrides inclusion filters set before config" do
          config.force(:inclusion_filter => {:foo => :bar})
          assign_files_or_directories_to_run "path/to/file.rb:37"
          expect(inclusion_filter.size).to eq(1)
          expect(inclusion_filter[:locations].keys.first).to match(/path\/to\/file\.rb$/)
          expect(inclusion_filter[:locations].values.first).to eq([37])
        end

        it "clears exclusion filters set before config" do
          config.force(:exclusion_filter => { :foo => :bar })
          assign_files_or_directories_to_run "path/to/file.rb:37"
          expect(config.exclusion_filter).to be_empty,
            "expected exclusion filter to be empty:\n#{config.exclusion_filter}"
        end
      end

      context "with default pattern" do
        it "loads files named _spec.rb" do
          assign_files_or_directories_to_run "spec/rspec/core/resources"
          expect(config.files_to_run).to contain_files("spec/rspec/core/resources/a_spec.rb", "spec/rspec/core/resources/acceptance/foo_spec.rb")
        end

        it "loads files in Windows", :if => RSpec::Support::OS.windows? do
          assign_files_or_directories_to_run "C:\\path\\to\\project\\spec\\sub\\foo_spec.rb"
          expect(config.files_to_run).to contain_files("C:/path/to/project/spec/sub/foo_spec.rb")
        end

        it "loads files in Windows when directory is specified", :failing_on_windows_ci, :if => RSpec::Support::OS.windows? do
          assign_files_or_directories_to_run "spec\\rspec\\core\\resources"
          expect(config.files_to_run).to contain_files("spec/rspec/core/resources/a_spec.rb")
        end

        it_behaves_like "handling symlinked directories when loading spec files" do
          def loaded_files
            assign_files_or_directories_to_run "spec"
            config.files_to_run
          end
        end
      end

      context "with default default_path" do
        it "loads files in the default path when run by rspec" do
          allow(config).to receive(:command) { 'rspec' }
          assign_files_or_directories_to_run []
          expect(config.files_to_run).not_to be_empty
        end

        it "loads files in the default path when run with DRB (e.g., spork)" do
          allow(config).to receive(:command) { 'spork' }
          allow(RSpec::Core::Runner).to receive(:running_in_drb?) { true }
          assign_files_or_directories_to_run []
          expect(config.files_to_run).not_to be_empty
        end

        it "does not load files in the default path when run by ruby" do
          allow(config).to receive(:command) { 'ruby' }
          assign_files_or_directories_to_run []
          expect(config.files_to_run).to be_empty
        end
      end

      it 'loads files in passed directories in alphabetical order to avoid OS-specific file-globbing non-determinism' do
        define_dirs "spec/unit" => [
          ["spec/unit/b_spec.rb", "spec/unit/a_spec.rb"],
          ["spec/unit/a_spec.rb", "spec/unit/b_spec.rb"]
        ]

        expect(assign_files_or_directories_to_run "spec/unit").to match [
          file_at("spec/unit/a_spec.rb"),
          file_at("spec/unit/b_spec.rb")
        ]
        expect(assign_files_or_directories_to_run "spec/unit").to match [
          file_at("spec/unit/a_spec.rb"),
          file_at("spec/unit/b_spec.rb")
        ]
      end

      it 'respects the user-specified order of files and directories passed at the command line' do
        define_dirs "spec/b" => [["spec/b/1_spec.rb", "spec/b/2_spec.rb"]],
                    "spec/c" => [["spec/c/1_spec.rb", "spec/c/2_spec.rb"]]

        expect(assign_files_or_directories_to_run "spec/b", "spec/a1_spec.rb", "spec/c", "spec/a2_spec.rb").to match [
          file_at("spec/b/1_spec.rb"), file_at("spec/b/2_spec.rb"),
          file_at("spec/a1_spec.rb"),
          file_at("spec/c/1_spec.rb"), file_at("spec/c/2_spec.rb"),
          file_at("spec/a2_spec.rb")
        ]
      end

      it 'deduplicates spec files that are listed individually and present in a passed dir' do
        define_dirs "spec/unit" => [[
          "spec/unit/a_spec.rb",
          "spec/unit/b_spec.rb",
          "spec/unit/c_spec.rb"
        ]]

        expect(assign_files_or_directories_to_run "spec/unit/b_spec.rb", "spec/unit").to match [
          file_at("spec/unit/b_spec.rb"),
          file_at("spec/unit/a_spec.rb"),
          file_at("spec/unit/c_spec.rb")
        ]

        expect(assign_files_or_directories_to_run "spec/unit", "spec/unit/b_spec.rb").to match [
          file_at("spec/unit/a_spec.rb"),
          file_at("spec/unit/b_spec.rb"),
          file_at("spec/unit/c_spec.rb")
        ]
      end

      def define_dirs(dirs_hash)
        allow(File).to receive(:directory?) do |path|
          !path.end_with?(".rb")
        end

        allow(Dir).to receive(:[]).and_return([])

        dirs_hash.each do |dir, sequential_glob_return_values|
          allow(Dir).to receive(:[]).with(
            a_string_including(dir, config.pattern)
          ).and_return(*sequential_glob_return_values)
        end
      end

      def file_at(relative_path)
        eq(relative_path).or eq(File.expand_path(relative_path))
      end
    end

    describe "#pattern" do
      context "with single pattern" do
        before { config.pattern = "**/*_foo.rb" }

        it "loads all explicitly specified files, even those that do not match the pattern" do
          file_1 = File.expand_path(File.dirname(__FILE__) + "/resources/a_foo.rb")
          file_2 = File.expand_path(File.dirname(__FILE__) + "/resources/a_bar.rb")

          assign_files_or_directories_to_run file_1, file_2
          expect(config.files_to_run).to contain_exactly(file_1, file_2)
        end

        it "loads files in directories following pattern" do
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).to include("#{dir}/a_foo.rb")
        end

        it "does not load files in directories not following pattern" do
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).not_to include("#{dir}/a_bar.rb")
        end

        it "ignores pattern if files are specified" do
          files = [
            File.expand_path(File.dirname(__FILE__) + "/resources/a_foo.rb"),
            File.expand_path(File.dirname(__FILE__) + "/resources/a_spec.rb")
          ]
          assign_files_or_directories_to_run(files)
          expect(config.files_to_run).to match_array(files)
        end
      end

      context "with multiple patterns" do
        it "supports comma separated values" do
          config.pattern = "**/*_foo.rb,**/*_bar.rb"
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).to include("#{dir}/a_foo.rb")
          expect(config.files_to_run).to include("#{dir}/a_bar.rb")
        end

        it "supports comma separated values with spaces" do
          config.pattern = "**/*_foo.rb, **/*_bar.rb"
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).to include("#{dir}/a_foo.rb")
          expect(config.files_to_run).to include("#{dir}/a_bar.rb")
        end

        it "supports curly braces glob syntax" do
          config.pattern = "**/*_{foo,bar}.rb"
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).to include("#{dir}/a_foo.rb")
          expect(config.files_to_run).to include("#{dir}/a_bar.rb")
        end
      end

      context "after files have already been loaded" do
        it 'warns that it will have no effect' do
          expect_warning_with_call_site(__FILE__, __LINE__ + 2, /has no effect/)
          config.load_spec_files
          config.pattern = "rspec/**/*.spec"
        end

        it 'does not warn if reset is called after load_spec_files' do
          config.load_spec_files
          config.reset
          expect(RSpec).to_not receive(:warning)
          config.pattern = "rspec/**/*.spec"
        end
      end

      context "after `files_to_run` has been accessed but before files have been loaded" do
        it 'still takes affect' do
          file = File.expand_path(File.dirname(__FILE__) + "/resources/a_foo.rb")
          assign_files_or_directories_to_run File.dirname(file)
          expect(config.files_to_run).not_to include(file)
          config.pattern = "**/*_foo.rb"
          expect(config.files_to_run).to include(file)
        end
      end
    end

    describe "#exclude_pattern" do
      context "with single pattern" do
        before { config.exclude_pattern = "**/*_foo.rb" }

        it "does not load files in directories following exclude pattern" do
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).not_to include("#{dir}/a_foo.rb")
        end

        it "loads files in directories not following exclude pattern" do
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).to include("#{dir}/a_spec.rb")
        end

        it "ignores exclude_pattern if files are specified" do
          files = [
            File.expand_path(File.dirname(__FILE__) + "/resources/a_foo.rb"),
            File.expand_path(File.dirname(__FILE__) + "/resources/a_spec.rb")
          ]
          assign_files_or_directories_to_run(files)
          expect(config.files_to_run).to match_array(files)
        end
      end

      context "with multiple patterns" do
        it "supports comma separated values" do
          config.exclude_pattern = "**/*_foo.rb,**/*_bar.rb"
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).not_to include("#{dir}/a_foo.rb")
          expect(config.files_to_run).not_to include("#{dir}/a_bar.rb")
        end

        it "supports comma separated values with spaces" do
          config.exclude_pattern = "**/*_foo.rb, **/*_bar.rb"
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).not_to include("#{dir}/a_foo.rb")
          expect(config.files_to_run).not_to include("#{dir}/a_bar.rb")
        end

        it "supports curly braces glob syntax" do
          config.exclude_pattern = "**/*_{foo,bar}.rb"
          dir = File.expand_path(File.dirname(__FILE__) + "/resources")
          assign_files_or_directories_to_run dir
          expect(config.files_to_run).not_to include("#{dir}/a_foo.rb")
          expect(config.files_to_run).not_to include("#{dir}/a_bar.rb")
        end
      end

      context "after files have already been loaded" do
        it 'warns that it will have no effect' do
          expect_warning_with_call_site(__FILE__, __LINE__ + 2, /has no effect/)
          config.load_spec_files
          config.exclude_pattern = "rspec/**/*.spec"
        end

        it 'does not warn if reset is called after load_spec_files' do
          config.load_spec_files
          config.reset
          expect(RSpec).to_not receive(:warning)
          config.exclude_pattern = "rspec/**/*.spec"
        end
      end

      context "after `files_to_run` has been accessed but before files have been loaded" do
        it 'still takes affect' do
          config.pattern = "**/*.rb"
          file = File.expand_path(File.dirname(__FILE__) + "/resources/a_foo.rb")
          assign_files_or_directories_to_run File.dirname(file)
          expect(config.files_to_run).to include(file)
          config.exclude_pattern = "**/*_foo.rb"
          expect(config.files_to_run).not_to include(file)
        end
      end
    end

    context "with full_description set" do
      it "overrides filters" do
        config.filter_run :focused => true
        config.full_description = "foo"
        expect(inclusion_filter).not_to have_key(:focused)
      end

      it 'is possible to access the full description regular expression' do
        config.full_description = "foo"
        expect(config.full_description).to eq(/foo/)
      end
    end

    context "without full_description having been set" do
      it 'returns nil from #full_description' do
        expect(config.full_description).to eq nil
      end
    end

    context "with line number" do
      it "assigns the file and line number as a location filter" do
        assign_files_or_directories_to_run "path/to/a_spec.rb:37"
        expect(inclusion_filter).to eq({:locations => {File.expand_path("path/to/a_spec.rb") => [37]}})
      end

      it "assigns multiple files with line numbers as location filters" do
        assign_files_or_directories_to_run "path/to/a_spec.rb:37", "other_spec.rb:44"
        expect(inclusion_filter).to eq({:locations => {File.expand_path("path/to/a_spec.rb") => [37],
                                                File.expand_path("other_spec.rb") => [44]}})
      end

      it "assigns files with multiple line numbers as location filters" do
        assign_files_or_directories_to_run "path/to/a_spec.rb:37", "path/to/a_spec.rb:44"
        expect(inclusion_filter).to eq({:locations => {File.expand_path("path/to/a_spec.rb") => [37, 44]}})
      end
    end

    context "with multiple line numbers" do
      it "assigns the file and line numbers as a location filter" do
        assign_files_or_directories_to_run "path/to/a_spec.rb:1:3:5:7"
        expect(inclusion_filter).to eq({:locations => {File.expand_path("path/to/a_spec.rb") => [1,3,5,7]}})
      end
    end

    it "allows file names with brackets" do
      assign_files_or_directories_to_run "./path/to/a_[1:2]spec.rb"
      expect(config.files_to_run).to contain_files("./path/to/a_[1:2]spec.rb")

      assign_files_or_directories_to_run "./path/to/a_spec.rb[foo]"
      expect(config.files_to_run).to contain_files("./path/to/a_spec.rb[foo]")
    end

    context "with an example id" do
      it "assigns the file and id as an ids filter" do
        assign_files_or_directories_to_run "./path/to/a_spec.rb[1:2]"
        expect(inclusion_filter).to eq(:ids => { "./path/to/a_spec.rb" => ["1:2"] })
      end
    end

    context "with a single file with multiple example ids" do
      it "assigns the file and ids as an ids filter" do
        assign_files_or_directories_to_run "./path/to/a_spec.rb[1:2,1:3]"
        expect(inclusion_filter).to eq(:ids => { "./path/to/a_spec.rb" => ["1:2", "1:3"] })
      end

      it "ignores whitespace between scoped ids" do
        assign_files_or_directories_to_run "./path/to/a_spec.rb[1:2 , 1:3]"
        expect(inclusion_filter).to eq(:ids => { "./path/to/a_spec.rb" => ["1:2", "1:3"] })
      end
    end

    context "with multiple files with ids" do
      it "assigns all of them to the ids filter" do
        assign_files_or_directories_to_run "./path/to/a_spec.rb[1:2,1:3]", "./path/to/b_spec.rb[1:4]"
        expect(inclusion_filter).to eq(:ids => {
          "./path/to/a_spec.rb" => ["1:2", "1:3"],
          "./path/to/b_spec.rb" => ["1:4"]
        })
      end
    end

    context "with the same file specified multiple times with different scoped ids" do
      it "unions all the ids" do
        assign_files_or_directories_to_run "./path/to/a_spec.rb[1:2]", "./path/to/a_spec.rb[1:3]"
        expect(inclusion_filter).to eq(:ids => { "./path/to/a_spec.rb" => ["1:2", "1:3"] })
      end
    end

    it "assigns the example name as the filter on description" do
      config.full_description = "foo"
      expect(inclusion_filter).to eq({:full_description => /foo/})
    end

    it "assigns the example names as the filter on description if description is an array" do
      config.full_description = [ "foo", "bar" ]
      expect(inclusion_filter).to eq({:full_description => Regexp.union(/foo/, /bar/)})
    end

    it 'is possible to access the full description regular expression' do
      config.full_description = "foo","bar"
      expect(config.full_description).to eq Regexp.union(/foo/,/bar/)
    end

    describe "#default_path" do
      it 'defaults to "spec"' do
        expect(config.default_path).to eq('spec')
      end

      it 'adds to the `project_source_dirs`' do
        expect {
          config.default_path = 'test'
        }.to change { config.project_source_dirs.include?('test') }.from(false).to(true)
      end
    end

    config_methods = %w[ include extend ]
    config_methods << "prepend" if RSpec::Support::RubyFeatures.module_prepends_supported?
    config_methods.each do |config_method|
      it "raises an immediate `TypeError` when you attempt to `config.#{config_method}` with something besides a module" do
        expect {
          config.send(config_method, :not_a_module)
        }.to raise_error(TypeError, a_string_including(
          "configuration.#{config_method}",
          "expects a module but got", "not_a_module"
        ))
      end
    end

    describe "#include_context" do
      context "with no metadata filters" do
        it 'includes the named shared example group in all groups' do
          RSpec.shared_examples "shared group" do
            let(:foo) { 17 }
          end
          RSpec.configuration.include_context "shared group"

          expect(RSpec.describe.new.foo).to eq 17
        end
      end

      context "with metadata filters" do
        it 'includes the named shared example group in matching groups' do
          RSpec.shared_examples "shared group" do
            let(:foo) { 18 }
          end
          RSpec.configuration.include_context "shared group", :include_it

          expect(RSpec.describe.new).not_to respond_to(:foo)
          expect(RSpec.describe("", :include_it).new.foo).to eq 18
        end

        it 'includes the named shared example group in the singleton class of matching examples' do
          RSpec.shared_examples "shared group" do
            let(:foo) { 19 }
          end
          RSpec.configuration.include_context "shared group", :include_it

          foo_value = nil
          describe_successfully do
            it { expect { self.foo }.to raise_error(NoMethodError) }
            it("", :include_it) { foo_value = foo }
          end

          expect(foo_value).to eq 19
        end
      end
    end

    describe "#include" do
      include_examples "warning of deprecated `:example_group` during filtering configuration", :include, Enumerable

      module InstanceLevelMethods
        def you_call_this_a_blt?
          "egad man, where's the mayo?!?!?"
        end
      end

      it_behaves_like "metadata hash builder" do
        def metadata_hash(*args)
          config.include(InstanceLevelMethods, *args)
          config.instance_variable_get(:@include_modules).items_and_filters.last.last
        end
      end

      context "with no filter" do
        it "includes the given module into each example group" do
          RSpec.configure do |c|
            c.include(InstanceLevelMethods)
          end

          group = RSpec.describe('does like, stuff and junk', :magic_key => :include) { }
          expect(group).not_to respond_to(:you_call_this_a_blt?)
          expect(group.new.you_call_this_a_blt?).to eq("egad man, where's the mayo?!?!?")
        end

        it "includes the given module into each existing example group" do
          group = RSpec.describe('does like, stuff and junk', :magic_key => :include) { }

          RSpec.configure do |c|
            c.include(InstanceLevelMethods)
          end

          expect(group).not_to respond_to(:you_call_this_a_blt?)
          expect(group.new.you_call_this_a_blt?).to eq("egad man, where's the mayo?!?!?")
        end
      end

      context "with a filter" do
        it "includes the given module into each matching example group" do
          RSpec.configure do |c|
            c.include(InstanceLevelMethods, :magic_key => :include)
          end

          group = RSpec.describe('does like, stuff and junk', :magic_key => :include) { }
          expect(group).not_to respond_to(:you_call_this_a_blt?)
          expect(group.new.you_call_this_a_blt?).to eq("egad man, where's the mayo?!?!?")
        end

        it "includes in example groups that match a deprecated `:example_group` filter" do
          RSpec.configure do |c|
            c.include(InstanceLevelMethods, :example_group => { :file_path => /./ })
          end

          group = RSpec.describe('does like, stuff and junk')
          expect(group).not_to respond_to(:you_call_this_a_blt?)
          expect(group.new.you_call_this_a_blt?).to eq("egad man, where's the mayo?!?!?")
        end

        it "includes the given module into each existing matching example group" do
          matching_group = RSpec.describe('does like, stuff and junk', :magic_key => :include) { }
          non_matching_group = RSpec.describe
          nested_matching_group = non_matching_group.describe("", :magic_key => :include)

          RSpec.configure do |c|
            c.include(InstanceLevelMethods, :magic_key => :include)
          end

          expect(matching_group).not_to respond_to(:you_call_this_a_blt?)
          expect(matching_group.new.you_call_this_a_blt?).to eq("egad man, where's the mayo?!?!?")

          expect(non_matching_group).not_to respond_to(:you_call_this_a_blt?)
          expect(non_matching_group.new).not_to respond_to(:you_call_this_a_blt?)

          expect(nested_matching_group).not_to respond_to(:you_call_this_a_blt?)
          expect(nested_matching_group.new.you_call_this_a_blt?).to eq("egad man, where's the mayo?!?!?")
        end

        it "includes the given module into the singleton class of matching examples" do
          RSpec.configure do |c|
            c.include(InstanceLevelMethods, :magic_key => :include)
          end

          value = ex1 = ex2 = nil

          RSpec.describe("Group") do
            ex1 = example("ex", :magic_key => :include) do
              value = you_call_this_a_blt?
            end

            ex2 = example("ex") { you_call_this_a_blt? }
          end.run

          expect(ex1.execution_result.exception).to be_nil
          expect(value).to match(/egad/)
          expect(ex2.execution_result.exception).to be_a(NameError)
        end

        it "ensures that `before` hooks have access to the module methods, even when only included in the singleton class of one example" do
          RSpec.configure do |c|
            c.include(Module.new { def which_mod; :mod_1; end }, :mod_1)
            c.include(Module.new { def which_mod; :mod_2; end }, :mod_2)
          end

          ex1_value = ex2_value = ex3 = nil

          RSpec.describe("group") do
            before { @value = which_mod }
            example("ex", :mod_1) { ex1_value = @value }
            example("ex", :mod_2) { ex2_value = @value }
            ex3 = example("ex") { }
          end.run

          expect(ex1_value).to eq(:mod_1)
          expect(ex2_value).to eq(:mod_2)
          expect(ex3.execution_result.exception).to be_a(NameError)
        end

        it "does not include the module in an example's singleton class when it has already been included in the group" do
          mod = Module.new do
            def self.inclusions
              @inclusions ||= []
            end

            def self.included(klass)
              inclusions << klass
            end
          end

          RSpec.configure do |c|
            c.include mod, :magic_key
          end

          group = RSpec.describe("Group", :magic_key) do
            example("ex", :magic_key) { }
          end

          group.run
          expect(mod.inclusions).to eq([group])
        end
      end
    end

    describe "#extend" do
      include_examples "warning of deprecated `:example_group` during filtering configuration", :extend, Enumerable

      module ThatThingISentYou
        def that_thing
        end
      end

      it_behaves_like "metadata hash builder" do
        def metadata_hash(*args)
          config.extend(ThatThingISentYou, *args)
          config.instance_variable_get(:@extend_modules).items_and_filters.last.last
        end
      end

      it "extends the given module into each matching example group" do
        RSpec.configure do |c|
          c.extend(ThatThingISentYou, :magic_key => :extend)
        end

        group = RSpec.describe(ThatThingISentYou, :magic_key => :extend) { }
        expect(group).to respond_to(:that_thing)
      end

      it "extends the given module into each existing matching example group" do
        matching_group = RSpec.describe(ThatThingISentYou, :magic_key => :extend) { }
        non_matching_group = RSpec.describe
        nested_matching_group = non_matching_group.describe("Other", :magic_key => :extend)

        RSpec.configure do |c|
          c.extend(ThatThingISentYou, :magic_key => :extend)
        end

        expect(matching_group).to respond_to(:that_thing)
        expect(non_matching_group).not_to respond_to(:that_thing)
        expect(nested_matching_group).to respond_to(:that_thing)
      end
    end

    describe "#prepend", :if => RSpec::Support::RubyFeatures.module_prepends_supported? do
      include_examples "warning of deprecated `:example_group` during filtering configuration", :prepend, Enumerable

      module SomeRandomMod
        def foo
          "foobar"
        end
      end

      it_behaves_like "metadata hash builder" do
        def metadata_hash(*args)
          config.prepend(SomeRandomMod, *args)
          config.instance_variable_get(:@prepend_modules).items_and_filters.last.last
        end
      end

      context "with no filter" do
        it "prepends the given module into each example group" do
          RSpec.configure do |c|
            c.prepend(SomeRandomMod)
          end

          group = RSpec.describe('yo') { }
          expect(group.new.foo).to eq("foobar")
        end

        it "prepends the given module into each existing example group" do
          group = RSpec.describe('yo') { }

          RSpec.configure do |c|
            c.prepend(SomeRandomMod)
          end

          expect(group.new.foo).to eq("foobar")
        end
      end

      context "with a filter" do
        it "prepends the given module into each matching example group" do
          RSpec.configure do |c|
            c.prepend(SomeRandomMod, :magic_key => :include)
          end

          group = RSpec.describe('yo', :magic_key => :include) { }
          expect(group.new.foo).to eq("foobar")
        end

        it "prepends the given module into each existing matching example group" do
          matching_group = RSpec.describe('yo', :magic_key => :include) { }
          non_matching_group = RSpec.describe
          nested_matching_group = non_matching_group.describe('', :magic_key => :include)

          RSpec.configure do |c|
            c.prepend(SomeRandomMod, :magic_key => :include)
          end

          expect(matching_group.new.foo).to eq("foobar")
          expect(non_matching_group.new).not_to respond_to(:foo)
          expect(nested_matching_group.new.foo).to eq("foobar")
        end
      end

    end

    describe "#run_all_when_everything_filtered?" do
      it "defaults to false" do
        expect(config.run_all_when_everything_filtered?).to be(false)
      end

      it "can be queried by predicate method" do
        config.run_all_when_everything_filtered = true
        expect(config.run_all_when_everything_filtered?).to be(true)
      end
    end

    describe "#color_mode" do
      context ":automatic" do
        before do
          config.color_mode = :automatic
        end

        context "with output.tty?" do
          it "sets color_enabled?" do
            config.output_stream = StringIO.new
            allow(config.output_stream).to receive_messages(:tty? => true)
            expect(config.color_enabled?).to be true
          end
        end

        context "with !output.tty?" do
          it "sets !color_enabled?" do
            config.output_stream = StringIO.new
            allow(config.output_stream).to receive_messages(:tty? => false)
            expect(config.color_enabled?).to be false
          end
        end
      end

      context ":on" do
        before do
          config.color_mode = :on
        end

        context "with output.tty?" do
          it "sets color_enabled?" do
            config.output_stream = StringIO.new
            allow(config.output_stream).to receive_messages(:tty? => true)
            expect(config.color_enabled?).to be true
          end
        end

        context "with !output.tty?" do
          it "sets color_enabled?" do
            config.output_stream = StringIO.new
            allow(config.output_stream).to receive_messages(:tty? => false)
            expect(config.color_enabled?).to be true
          end
        end
      end

      context ":off" do
        before do
          config.color_mode = :off
        end

        context "with output.tty?" do
          it "sets !color_enabled?" do
            config.output_stream = StringIO.new
            allow(config.output_stream).to receive_messages(:tty? => true)
            expect(config.color_enabled?).to be false
          end
        end

        context "with !output.tty?" do
          it "sets !color_enabled?" do
            config.output_stream = StringIO.new
            allow(config.output_stream).to receive_messages(:tty? => false)
            expect(config.color_enabled?).to be false
          end
        end

        it "prefers incoming cli_args" do
          config.output_stream = StringIO.new
          config.force :color_mode => :on
          config.color_mode = :off
          expect(config.color_mode).to be :on
        end
      end
    end

    describe "#color_enabled?" do
      it "allows overriding instance output stream with an argument" do
        config.output_stream = StringIO.new
        output_override = StringIO.new

        config.color_mode = :automatic
        allow(config.output_stream).to receive_messages(:tty? => false)
        allow(output_override).to receive_messages(:tty? => true)

        expect(config.color_enabled?).to be false
        expect(config.color_enabled?(output_override)).to be true
      end
    end

    describe "#color=" do
      before { config.color_mode = :automatic }

      context "given false" do
        before { config.color = false }

        context "with config.tty? and output.tty?" do
          it "sets color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = true
            allow(config.output_stream).to receive_messages(:tty? => true)

            expect(config.color_enabled?).to be true
            expect(config.color_enabled?(output)).to be true
          end
        end

        context "with config.tty? and !output.tty?" do
          it "does not set color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = true
            allow(config.output_stream).to receive_messages(:tty? => false)

            expect(config.color_enabled?).to be false
            expect(config.color_enabled?(output)).to be false
          end
        end

        context "with !config.tty? and output.tty?" do
          it "sets color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = false
            allow(config.output_stream).to receive_messages(:tty? => true)

            expect(config.color_enabled?).to be true
            expect(config.color_enabled?(output)).to be true
          end
        end

        context "with !config.tty? and !output.tty?" do
          it "does not set color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = false
            allow(config.output_stream).to receive_messages(:tty? => false)

            expect(config.color_enabled?).to be false
            expect(config.color_enabled?(output)).to be false
          end
        end
      end

      context "given true" do
        before { config.color = true }

        context "with config.tty? and output.tty?" do
          it "sets color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = true
            allow(config.output_stream).to receive_messages(:tty? => true)

            expect(config.color_enabled?).to be true
            expect(config.color_enabled?(output)).to be true
          end
        end

        context "with config.tty? and !output.tty?" do
          it "sets color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = true
            allow(config.output_stream).to receive_messages(:tty? => false)

            expect(config.color_enabled?).to be true
            expect(config.color_enabled?(output)).to be true
          end
        end

        context "with !config.tty? and output.tty?" do
          it "sets color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = false
            allow(config.output_stream).to receive_messages(:tty? => true)

            expect(config.color_enabled?).to be true
            expect(config.color_enabled?(output)).to be true
          end
        end

        context "with !config.tty? and !output.tty?" do
          it "does not set color_enabled?" do
            output = StringIO.new
            config.output_stream = output

            config.tty = false
            allow(config.output_stream).to receive_messages(:tty? => false)

            expect(config.color_enabled?).to be false
            expect(config.color_enabled?(output)).to be false
          end
        end
      end

      it "prefers incoming cli_args" do
        config.output_stream = StringIO.new
        allow(config.output_stream).to receive_messages(:tty? => true)
        config.force :color => true
        config.color = false
        expect(config.color).to be true
      end
    end

    describe "#bisect_runner_class" do
      if RSpec::Support::RubyFeatures.fork_supported?
        it 'defaults to the faster `Bisect::ForkRunner` since fork is supported on this platform' do
          expect(config.bisect_runner_class).to be Bisect::ForkRunner
        end
      else
        it 'defaults to the slower `Bisect::ShellRunner` since fork is not supported on this platform' do
          expect(config.bisect_runner_class).to be Bisect::ShellRunner
        end
      end

      it "returns `Bisect::ForkRunner` when `bisect_runner == :fork" do
        config.bisect_runner = :fork
        expect(config.bisect_runner_class).to be Bisect::ForkRunner
      end

      it "returns `Bisect::ShellRunner` when `bisect_runner == :shell" do
        config.bisect_runner = :shell
        expect(config.bisect_runner_class).to be Bisect::ShellRunner
      end

      it "raises a clear error when `bisect_runner` is configured to an unrecognized value" do
        config.bisect_runner = :unknown
        expect {
          config.bisect_runner_class
        }.to raise_error(/Unsupported value for `bisect_runner`/)
      end

      it 'cannot be changed after the runner is in use' do
        config.bisect_runner = :fork
        config.bisect_runner_class

        expect {
          config.bisect_runner = :shell
        }.to raise_error(/config.bisect_runner = :shell/)
      end

      it 'can be set to the same value after the runner is in use' do
        config.bisect_runner = :shell
        config.bisect_runner_class

        expect { config.bisect_runner = :shell }.not_to raise_error
      end
    end

    %w[formatter= add_formatter].each do |config_method|
      describe "##{config_method}" do
        it "delegates to formatters#add" do
          expect(config.formatter_loader).to receive(:add).with('these','options')
          config.send(config_method,'these','options')
        end
      end
    end

    describe "#formatters" do
      it "returns a dup of the formatter_loader formatters" do
        config.add_formatter 'doc'
        config.formatters.clear
        expect(config.formatters).to_not eq []
      end
    end

    describe '#reporter' do
      before do
        config.output_stream = StringIO.new
        config.deprecation_stream = StringIO.new
      end

      it 'does not immediately trigger formatter setup' do
        config.reporter

        expect(config.formatters).to be_empty
      end

      it 'buffers deprecations until the reporter is ready' do
        allow(config.formatter_loader).to receive(:prepare_default).and_wrap_original do |original, *args|
          config.reporter.deprecation :message => 'Test deprecation'
          original.call(*args)
        end
        expect {
          config.reporter.notify :deprecation_summary, Notifications::NullNotification
        }.to change { config.deprecation_stream.string }.to include 'Test deprecation'
      end

      it 'allows registering listeners without doubling up formatters' do
        config.reporter.register_listener double(:message => nil), :message

        expect {
          config.formatter = :documentation
        }.to change { config.formatters.size }.from(0).to(1)

        # notify triggers the formatter setup, there are two due to the already configured
        # documentation formatter and deprecation formatter
        expect {
          config.reporter.notify :message, double(:message => 'Triggers formatter setup')
        }.to change { config.formatters.size }.from(1).to(2)
      end

      it 'still configures a default formatter when none specified' do
        config.reporter.register_listener double(:message => nil), :message

        # notify triggers the formatter setup, there are two due to the default
        # (progress) and deprecation formatter
        expect {
          config.reporter.notify :message, double(:message => 'Triggers formatter setup')
        }.to change { config.formatters.size }.from(0).to(2)
      end
    end

    describe "#default_formatter" do
      it 'defaults to `progress`' do
        expect(config.default_formatter).to eq('progress')
      end

      it 'remembers changes' do
        config.default_formatter = 'doc'
        expect(config.default_formatter).to eq('doc')
      end

      context 'when another formatter has been set' do
        it 'does not get used' do
          config.default_formatter = 'doc'
          config.add_formatter 'progress'

          expect(used_formatters).to include(an_instance_of Formatters::ProgressFormatter)
          expect(used_formatters).not_to include(an_instance_of Formatters::DocumentationFormatter)
        end
      end

      context 'when no other formatter has been set' do
        before do
          config.output_stream = StringIO.new
        end

        it 'gets used' do
          config.default_formatter = 'doc'
          config.reporter.notify :message, double(:message => 'Triggers formatter setup')

          expect(used_formatters).not_to include(an_instance_of Formatters::ProgressFormatter)
          expect(used_formatters).to include(an_instance_of Formatters::DocumentationFormatter)
        end
      end

      context 'using a legacy formatter as default' do
        # Generating warnings during formatter initialisation triggers the
        # ProxyReporter code path.
        it 'remembers changes' do
          legacy_formatter = Class.new

          configuration = RSpec.configuration
          configuration.default_formatter = legacy_formatter
          configuration.reporter
          expect(configuration.default_formatter).to eq(legacy_formatter)
        end
      end

      def used_formatters
        config.reporter # to force freezing of formatters
        config.formatters
      end
    end

    describe "#filter_run_including" do
      it_behaves_like "metadata hash builder" do
        def metadata_hash(*args)
          config.filter_run_including(*args)
          config.inclusion_filter.rules
        end
      end

      include_examples "warning of deprecated `:example_group` during filtering configuration", :filter_run_including

      it "sets the filter with a hash" do
        config.filter_run_including :foo => true
        expect(inclusion_filter).to eq( {:foo => true} )
      end

      it "sets the filter with a symbol" do
        config.filter_run_including :foo
        expect(inclusion_filter).to eq( {:foo => true} )
      end

      it "merges with existing filters" do
        config.filter_run_including :foo => true
        config.filter_run_including :bar => false
        expect(inclusion_filter).to eq( {:foo => true, :bar => false} )
      end
    end

    describe "#filter_run_excluding" do
      it_behaves_like "metadata hash builder" do
        def metadata_hash(*args)
          config.filter_run_excluding(*args)
          config.exclusion_filter.rules
        end
      end

      include_examples "warning of deprecated `:example_group` during filtering configuration", :filter_run_excluding

      it "sets the filter" do
        config.filter_run_excluding :foo => true
        expect(exclusion_filter).to eq( {:foo => true} )
      end

      it "sets the filter using a symbol" do
        config.filter_run_excluding :foo
        expect(exclusion_filter).to eq( {:foo => true} )
      end

      it "merges with existing filters" do
        config.filter_run_excluding :foo => true
        config.filter_run_excluding :bar => false
        expect(exclusion_filter).to eq( {:foo => true, :bar => false} )
      end
    end

    shared_examples_for "a spec filter" do |type|
      describe "##{type}" do
        it "returns {} even if set to nil" do
          config.send("#{type}=", nil)
          expect(send(type)).to eq({})
        end
      end

      describe "##{type}=" do
        it "treats symbols as hash keys with true values when told to" do
          config.send("#{type}=", :foo)
          expect(send(type)).to eq( {:foo => true} )
        end

        it "overrides any #{type} set on the command line or in configuration files" do
          config.force(type => { :foo => :bar })
          config.send("#{type}=", {:want => :this})
          expect(send(type)).to eq( {:want => :this} )
        end

        include_examples "warning of deprecated `:example_group` during filtering configuration", :"#{type}="
      end
    end
    it_behaves_like "a spec filter", :inclusion_filter
    it_behaves_like "a spec filter", :exclusion_filter

    describe "#treat_symbols_as_metadata_keys_with_true_values=" do
      it 'is deprecated' do
        expect_deprecation_with_call_site(__FILE__, __LINE__ + 1)
        config.treat_symbols_as_metadata_keys_with_true_values = true
      end
    end

    describe "#full_backtrace=" do
      it "doesn't impact other instances of config" do
        config_1 = Configuration.new
        config_2 = Configuration.new

        config_1.full_backtrace = true
        expect(config_2.full_backtrace?).to be(false)
      end
    end

    describe "#backtrace_exclusion_patterns=" do
      it "actually receives the new filter values" do
        config.backtrace_exclusion_patterns = [/.*/]
        expect(config.backtrace_formatter.exclude? "this").to be(true)
      end
    end

    describe 'full_backtrace' do
      it 'returns true when backtrace patterns is empty' do
        config.backtrace_exclusion_patterns = []
        expect(config.full_backtrace?).to eq true
      end

      it 'returns false when backtrace patterns isnt empty' do
        config.backtrace_exclusion_patterns = [:lib]
        expect(config.full_backtrace?).to eq false
      end
    end

    describe "#backtrace_exclusion_patterns" do
      it "can be appended to" do
        config.backtrace_exclusion_patterns << /.*/
        expect(config.backtrace_formatter.exclude? "this").to be(true)
      end
    end

    describe "#backtrace_inclusion_patterns" do
      before { config.backtrace_exclusion_patterns << /.*/ }

      it 'can be assigned to' do
        config.backtrace_inclusion_patterns = [/foo/]
        expect(config.backtrace_formatter.exclude?("food")).to be false
      end

      it 'can be appended to' do
        config.backtrace_inclusion_patterns << /foo/
        expect(config.backtrace_formatter.exclude?("food")).to be false
      end
    end

    describe "#filter_gems_from_backtrace" do
      def exclude?(line)
        config.backtrace_formatter.exclude?(line)
      end

      it 'filters the named gems from the backtrace' do
        line_1 = "/Users/myron/.gem/ruby/2.1.1/gems/foo-1.6.3.1/foo.rb:13"
        line_2 = "/Users/myron/.gem/ruby/2.1.1/gems/bar-1.6.3.1/bar.rb:13"

        expect {
          config.filter_gems_from_backtrace "foo", "bar"
        }.to change { exclude?(line_1) }.from(false).to(true).
         and change { exclude?(line_2) }.from(false).to(true)
      end
    end

    describe "#profile_examples" do
      it "defaults to false" do
        expect(config.profile_examples).to be false
      end

      it "can be set to an integer value" do
        config.profile_examples = 17
        expect(config.profile_examples).to eq(17)
      end

      it "returns 10 when set simply enabled" do
        config.profile_examples = true
        expect(config.profile_examples).to eq(10)
      end
    end

    describe "#libs=" do
      it "adds directories to the LOAD_PATH" do
        expect($LOAD_PATH).to receive(:unshift).with("a/dir")
        config.libs = ["a/dir"]
      end
    end

    describe "libs" do
      it 'records paths added to the load path' do
        config.libs = ["a/dir"]
        expect(config.libs).to eq ["a/dir"]
      end
    end

    describe "#define_derived_metadata" do
      include_examples "warning of deprecated `:example_group` during filtering configuration", :define_derived_metadata

      it 'allows the provided block to mutate example group metadata' do
        RSpec.configuration.define_derived_metadata do |metadata|
          metadata[:reverse_description] = metadata[:description].reverse
        end

        group = RSpec.describe("My group")
        expect(group.metadata).to include(:description => "My group", :reverse_description => "puorg yM")
      end

      it 'allows the provided block to mutate example metadata' do
        RSpec.configuration.define_derived_metadata do |metadata|
          metadata[:reverse_description] = metadata[:description].reverse
        end

        ex = RSpec.describe("My group").example("foo")
        expect(ex.metadata).to include(:description => "foo", :reverse_description => "oof")
      end

      it 'allows multiple configured blocks to be applied, in order of definition' do
        RSpec.configure do |c|
          c.define_derived_metadata { |m| m[:b1_desc] = m[:description] + " (block 1)" }
          c.define_derived_metadata { |m| m[:b2_desc] = m[:b1_desc]     + " (block 2)" }
        end

        group = RSpec.describe("bar")
        expect(group.metadata).to include(:b1_desc => "bar (block 1)", :b2_desc => "bar (block 1) (block 2)")
      end

      it 'supports cascades of derived metadata, but avoids re-running derived metadata blocks that have already been applied' do
        RSpec.configure do |c|
          c.define_derived_metadata(:foo1) { |m| m[:foo2] = (m[:foo2] || 0) + 1 }
          c.define_derived_metadata(:foo2) { |m| m[:foo3] = (m[:foo3] || 0) + 1 }
          c.define_derived_metadata(:foo3) { |m| m[:foo1] += 1 }
        end

        group = RSpec.describe("bar", :foo1 => 0)
        expect(group.metadata).to include(:foo1 => 1, :foo2 => 1, :foo3 => 1)

        ex = RSpec.describe("My group").example("foo", :foo1 => 0)
        expect(ex.metadata).to include(:foo1 => 1, :foo2 => 1, :foo3 => 1)
      end

      it 'does not allow a derived metadata cascade to recurse infinitely' do
        RSpec.configure do |c|
          counter = 1
          derive_next_metadata = lambda do |outer_meta|
            tag = :"foo#{counter += 1}"
            outer_meta[tag] = true

            c.define_derived_metadata(tag) do |inner_meta|
              derive_next_metadata.call(inner_meta)
            end
          end

          c.define_derived_metadata(:foo1) do |meta|
            derive_next_metadata.call(meta)
          end
        end

        expect {
          RSpec.describe("group", :foo1)
        }.to raise_error(SystemStackError)
      end

      it "derives metadata before the group or example blocks are eval'd so their logic can depend on the derived metadata" do
        RSpec.configure do |c|
          c.define_derived_metadata(:foo) do |metadata|
            metadata[:bar] = "bar"
          end
        end

        group_bar_value = example_bar_value = nil

        RSpec.describe "Group", :foo do
          group_bar_value = self.metadata[:bar]
          example_bar_value = example("ex", :foo).metadata[:bar]
        end

        expect(group_bar_value).to eq("bar")
        expect(example_bar_value).to eq("bar")
      end

      it 'registers top-level groups before invoking the callback so the logic can configure already registered groups' do
        registered_groups = nil

        RSpec.configuration.define_derived_metadata do |_meta|
          registered_groups = RSpec.world.example_groups
        end

        group = RSpec.describe("My group") do
        end

        expect(registered_groups).to eq [group]
      end

      it 'registers nested groups before invoking the callback so the logic can configure already registered groups' do
        registered_groups = nil

        RSpec.configuration.define_derived_metadata(:inner) do |_meta|
          registered_groups = RSpec.world.all_example_groups
        end

        inner = nil
        outer = RSpec.describe("Outer") do
          inner = context "Inner", :inner do
          end
        end

        expect(registered_groups).to contain_exactly(outer, inner)
      end

      it 'registers examples before invoking the callback so the logic can configure already registered groups' do
        registered_examples = nil

        RSpec.configuration.define_derived_metadata(:ex) do |_meta|
          registered_examples = FlatMap.flat_map(RSpec.world.all_example_groups, &:examples)
        end

        example = nil
        RSpec.describe("Outer") do
          example = example("ex", :ex)
        end

        expect(registered_examples).to contain_exactly(example)
      end

      context "when passed a metadata filter" do
        it 'only applies to the groups and examples that match that filter' do
          RSpec.configure do |c|
            c.define_derived_metadata(:apply => true) do |metadata|
              metadata[:reverse_description] = metadata[:description].reverse
            end
          end

          g1 = RSpec.describe("G1", :apply)
          g2 = RSpec.describe("G2")
          e1 = g1.example("E1")
          e2 = g2.example("E2", :apply)
          e3 = g2.example("E3")

          expect(g1.metadata).to include(:reverse_description => "1G")
          expect(g2.metadata).not_to include(:reverse_description)

          expect(e1.metadata).to include(:reverse_description => "1E")
          expect(e2.metadata).to include(:reverse_description => "2E")
          expect(e3.metadata).not_to include(:reverse_description)
        end

        it 'applies if any of multiple filters apply (to align with module inclusion semantics)' do
          RSpec.configure do |c|
            c.define_derived_metadata(:a => 1, :b => 2) do |metadata|
              metadata[:reverse_description] = metadata[:description].reverse
            end
          end

          g1 = RSpec.describe("G1", :a => 1)
          g2 = RSpec.describe("G2", :b => 2)
          g3 = RSpec.describe("G3", :c => 3)

          expect(g1.metadata).to include(:reverse_description => "1G")
          expect(g2.metadata).to include(:reverse_description => "2G")
          expect(g3.metadata).not_to include(:reverse_description)
        end

        it 'allows a metadata filter to be passed as a raw symbol' do
          RSpec.configure do |c|
            c.define_derived_metadata(:apply) do |metadata|
              metadata[:reverse_description] = metadata[:description].reverse
            end
          end

          g1 = RSpec.describe("G1", :apply)
          g2 = RSpec.describe("G2")

          expect(g1.metadata).to include(:reverse_description => "1G")
          expect(g2.metadata).not_to include(:reverse_description)
        end
      end
    end

    describe "#when_first_matching_example_defined" do
      include_examples "warning of deprecated `:example_group` during filtering configuration", :when_first_matching_example_defined

      it "runs the block when the first matching example is defined" do
        sequence = []
        RSpec.configuration.when_first_matching_example_defined(:foo) do
          sequence << :callback
        end

        RSpec.describe do
          example("ex 1")
          sequence << :before_first_matching_example_defined
          example("ex 2", :foo)
          sequence << :after_first_matching_example_defined
        end

        expect(sequence).to eq [:before_first_matching_example_defined, :callback, :after_first_matching_example_defined]
      end

      it "does not fire when later matching examples are defined" do
        sequence = []
        RSpec.configuration.when_first_matching_example_defined(:foo) do
          sequence << :callback
        end

        RSpec.describe do
          example("ex 1", :foo)
          sequence.clear

          sequence << :before_second_matching_example_defined
          example("ex 2", :foo)
          sequence << :after_second_matching_example_defined
        end

        expect(sequence).to eq [:before_second_matching_example_defined, :after_second_matching_example_defined]
      end

      it "does not run the block if no matching examples are defined" do
        sequence = []
        RSpec.configuration.when_first_matching_example_defined(:foo) do
          sequence << :callback
        end

        RSpec.describe do
          example("ex 1")
          example("ex 2", :bar)
        end

        expect(sequence).to eq []
      end

      it 'does not run the block if groups match the metadata but no examples do' do
        called = false
        RSpec.configuration.when_first_matching_example_defined(:foo => true) do
          called = true
        end

        RSpec.describe "group 1", :foo => true do
        end

        RSpec.describe "group 2", :foo => true do
          example("ex", :foo => false)
        end

        expect(called).to be false
      end

      it "still runs after the first matching example even if there is a group that matches earlier" do
        sequence = []
        RSpec.configuration.when_first_matching_example_defined(:foo) do
          sequence << :callback
        end

        RSpec.describe "group", :foo do
        end

        RSpec.describe do
          example("ex 1")
          sequence << :before_first_matching_example_defined
          example("ex 2", :foo)
          sequence << :after_first_matching_example_defined
        end

        expect(sequence).to eq [:before_first_matching_example_defined, :callback, :after_first_matching_example_defined]
      end

      context "when a group is defined with matching metadata" do
        it "runs the callback after the first example in the group is defined" do
          sequence = []
          RSpec.configuration.when_first_matching_example_defined(:foo) do
            sequence << :callback
          end

          sequence << :before_group
          RSpec.describe "group", :foo do
            sequence << :before_example
            example("ex")
            sequence << :after_example
          end

          expect(sequence).to eq [:before_group, :before_example, :callback, :after_example]
        end
      end

      context 'when the value of the registered metadata is a Proc' do
        it 'does not fire when later matching examples are defined' do
          sequence = []
          RSpec.configuration.when_first_matching_example_defined(:foo => proc { true }) do
            sequence << :callback
          end

          RSpec.describe do
            example("ex 1", :foo)
            sequence.clear

            sequence << :before_second_matching_example_defined
            example("ex 2", :foo)
            sequence << :after_second_matching_example_defined
          end

          expect(sequence).to eq [:before_second_matching_example_defined, :after_second_matching_example_defined]
        end
      end

      context 'when a matching example group with other registered metadata has been defined' do
        it 'does not fire when later matching examples with the other metadata are defined' do
          sequence = []

          RSpec.configuration.when_first_matching_example_defined(:foo) do
            sequence << :callback
          end

          RSpec.configuration.when_first_matching_example_defined(:bar) do
          end

          RSpec.describe 'group', :foo, :bar do
            example("ex 1", :foo)
            sequence.clear

            sequence << :before_second_matching_example_defined
            example("ex 2", :foo, :bar)
            sequence << :after_second_matching_example_defined
          end

          expect(sequence).to eq [:before_second_matching_example_defined, :after_second_matching_example_defined]
        end
      end
    end

    describe "#add_setting" do
      describe "with no modifiers" do
        context "with no additional options" do
          before do
            config.add_setting :custom_option
          end

          it "defaults to nil" do
            expect(config.custom_option).to be_nil
          end

          it "adds a predicate" do
            expect(config.custom_option?).to be(false)
          end

          it "can be overridden" do
            config.custom_option = "a value"
            expect(config.custom_option).to eq("a value")
          end
        end

        context "with :default => 'a value'" do
          before do
            config.add_setting :custom_option, :default => 'a value'
          end

          it "defaults to 'a value'" do
            expect(config.custom_option).to eq("a value")
          end

          it "returns true for the predicate" do
            expect(config.custom_option?).to be(true)
          end

          it "can be overridden with a truthy value" do
            config.custom_option = "a new value"
            expect(config.custom_option).to eq("a new value")
          end

          it "can be overridden with nil" do
            config.custom_option = nil
            expect(config.custom_option).to eq(nil)
          end

          it "can be overridden with false" do
            config.custom_option = false
            expect(config.custom_option).to eq(false)
          end
        end
      end

      context "with :alias_with => " do
        before do
          config.add_setting :custom_option, :alias_with => :another_custom_option
        end

        it "delegates the getter to the other option" do
          config.another_custom_option = "this value"
          expect(config.custom_option).to eq("this value")
        end

        it "delegates the setter to the other option" do
          config.custom_option = "this value"
          expect(config.another_custom_option).to eq("this value")
        end

        it "delegates the predicate to the other option" do
          config.custom_option = true
          expect(config.another_custom_option?).to be(true)
        end
      end
    end

    describe "#configure_group" do
      it "extends with 'extend'" do
        mod = Module.new
        group = RSpec.describe("group", :foo => :bar)

        config.extend(mod, :foo => :bar)
        config.configure_group(group)
        expect(group).to be_a(mod)
      end

      it "includes with 'include'" do
        mod = Module.new
        group = RSpec.describe("group", :foo => :bar)

        config.include(mod, :foo => :bar)
        config.configure_group(group)
        expect(group.included_modules).to include(mod)
      end

      it "requires only one matching filter" do
        mod = Module.new
        group = RSpec.describe("group", :foo => :bar)

        config.include(mod, :foo => :bar, :baz => :bam)
        config.configure_group(group)
        expect(group.included_modules).to include(mod)
      end

      module IncludeExtendOrPrependMeOnce
        def self.included(host)
          raise "included again" if host.instance_methods.include?(:foobar)
          host.class_exec { def foobar; end }
        end

        def self.extended(host)
          raise "extended again" if host.respond_to?(:foobar)
          def host.foobar; end
        end

        def self.prepended(host)
          raise "prepended again" if host.instance_methods.include?(:barbaz)
          host.class_exec { def barbaz; end }
        end
      end

      it "doesn't include a module when already included in ancestor" do
        config.include(IncludeExtendOrPrependMeOnce, :foo => :bar)

        group = RSpec.describe("group", :foo => :bar)
        child = group.describe("child")

        config.configure_group(group)
        config.configure_group(child)
      end

      it "doesn't extend when ancestor is already extended with same module" do
        config.extend(IncludeExtendOrPrependMeOnce, :foo => :bar)

        group = RSpec.describe("group", :foo => :bar)
        child = group.describe("child")

        config.configure_group(group)
        config.configure_group(child)
      end

      it "doesn't prepend a module when already present in ancestor chain",
        :if => RSpec::Support::RubyFeatures.module_prepends_supported? do
        config.prepend(IncludeExtendOrPrependMeOnce, :foo => :bar)

        group = RSpec.describe("group", :foo => :bar)
        child = group.describe("child")

        config.configure_group(group)
        config.configure_group(child)
      end
    end

    describe "#alias_example_group_to" do
      after do
        RSpec::Core::DSL.example_group_aliases.delete(:my_group_method)

        RSpec.module_exec do
          class << self
            undef :my_group_method if method_defined? :my_group_method
          end
        end

        RSpec::Core::ExampleGroup.module_exec do
          class << self
            undef :my_group_method if method_defined? :my_group_method
          end
        end

        Module.class_exec do
          undef :my_group_method if method_defined? :my_group_method
        end
      end

      it_behaves_like "metadata hash builder" do
        def metadata_hash(*args)
          config.alias_example_group_to :my_group_method, *args
          group = ExampleGroup.my_group_method("a group")
          group.metadata
        end
      end

      it 'overrides existing definitions of the aliased method name without issueing warnings' do
        config.expose_dsl_globally = true

        class << ExampleGroup
          def my_group_method; :original; end
        end

        Module.class_exec do
          def my_group_method; :original; end
        end

        config.alias_example_group_to :my_group_method

        expect(ExampleGroup.my_group_method).to be < ExampleGroup
        expect(Module.new.my_group_method).to be < ExampleGroup
      end

      it "allows adding additional metadata" do
        config.alias_example_group_to :my_group_method, { :some => "thing" }
        group = ExampleGroup.my_group_method("a group", :another => "thing")
        expect(group.metadata).to include(:some => "thing", :another => "thing")
      end

      it "passes `nil` as the description arg when no args are given" do
        config.alias_example_group_to :my_group_method, { :some => "thing" }
        group = ExampleGroup.my_group_method

        expect(group.metadata).to include(
          :description_args => [nil],
          :description => "",
          :some => "thing"
        )
      end

      context 'when the aliased method is used' do
        it_behaves_like "metadata hash builder" do
          def metadata_hash(*args)
            config.alias_example_group_to :my_group_method
            group = ExampleGroup.my_group_method("a group", *args)
            group.metadata
          end
        end
      end
    end

    describe "#alias_example_to" do
      it_behaves_like "metadata hash builder" do
        after do
          RSpec::Core::ExampleGroup.module_exec do
            class << self
              undef :my_example_method if method_defined? :my_example_method
            end
          end
        end
        def metadata_hash(*args)
          config.alias_example_to :my_example_method, *args
          group = RSpec.describe("group")
          example = group.my_example_method("description")
          example.metadata
        end
      end
    end

    describe "#reset" do
      it "clears the reporter" do
        expect(config.reporter).not_to be_nil
        config.reset
        expect(config.instance_variable_get("@reporter")).to be_nil
      end

      it "clears the formatters" do
        config.add_formatter "doc"
        config.reset
        expect(config.formatters).to be_empty
      end

      it "clears the output wrapper" do
        config.output_stream = StringIO.new
        config.reset
        expect(config.instance_variable_get("@output_wrapper")).to be_nil
      end
    end

    describe "#reset_reporter" do
      it "clears the reporter" do
        expect(config.reporter).not_to be_nil
        config.reset
        expect(config.instance_variable_get("@reporter")).to be_nil
      end

      it "clears the formatters" do
        config.add_formatter "doc"
        config.reset
        expect(config.formatters).to be_empty
      end

      it "clears the output wrapper" do
        config.output_stream = StringIO.new
        config.reset
        expect(config.instance_variable_get("@output_wrapper")).to be_nil
      end
    end

    def example_numbered(num)
      instance_double(Example, :id => "./foo_spec.rb[1:#{num}]")
    end

    describe "#force" do
      context "for ordering options" do
        let(:list) { 1.upto(4).map { |i| example_numbered(i) } }
        let(:ordering_strategy) { config.ordering_registry.fetch(:global) }
        let(:shuffled) { Ordering::Random.new(config).order list }

        specify "CLI `--order defined` takes precedence over `config.order = rand`" do
          config.force :order => "defined"
          config.order = "rand"

          expect(ordering_strategy.order(list)).to eq(list)
        end

        specify "CLI `--order rand:37` takes precedence over `config.order = defined`" do
          config.force :order => "rand:37"
          config.order = "defined"

          expect(ordering_strategy.order(list)).to eq(shuffled)
        end

        specify "CLI `--seed 37` forces order and seed" do
          config.force :seed => 37
          config.order = "defined"
          config.seed  = 145

          expect(ordering_strategy.order(list)).to eq(shuffled)
          expect(config.seed).to eq(37)
        end

        specify "CLI `--order defined` takes precedence over `config.register_ordering(:global)`" do
          config.force :order => "defined"
          config.register_ordering(:global, &:reverse)
          expect(ordering_strategy.order(list)).to eq(list)
        end
      end

      it "forces 'false' value" do
        config.add_setting :custom_option
        config.custom_option = true
        expect(config.custom_option?).to be(true)
        config.force :custom_option => false
        expect(config.custom_option?).to be(false)
        config.custom_option = true
        expect(config.custom_option?).to be(false)
      end
    end

    describe '#seed' do
      it 'returns the seed as an int' do
        config.seed = '123'
        expect(config.seed).to eq(123)
      end
    end

    describe "#seed_used?" do
      def use_seed_on(registry)
        registry.fetch(:random).order([example_numbered(1), example_numbered(2)])
      end

      it 'returns false if neither ordering registry used the seed' do
        expect(config.seed_used?).to be false
      end

      it 'returns true if the ordering registry used the seed' do
        use_seed_on(config.ordering_registry)
        expect(config.seed_used?).to be true
      end
    end

    describe '#order=' do
      context 'given "random"' do
        before do
          config.seed = 7654
          config.order = 'random'
        end

        it 'does not change the seed' do
          expect(config.seed).to eq(7654)
        end

        it 'sets up random ordering' do
          allow(RSpec).to receive_messages(:configuration => config)
          global_ordering = config.ordering_registry.fetch(:global)
          expect(global_ordering).to be_an_instance_of(Ordering::Random)
        end
      end

      context 'given "random:123"' do
        before { config.order = 'random:123' }

        it 'sets seed to 123' do
          expect(config.seed).to eq(123)
        end

        it 'sets up random ordering' do
          allow(RSpec).to receive_messages(:configuration => config)
          global_ordering = config.ordering_registry.fetch(:global)
          expect(global_ordering).to be_an_instance_of(Ordering::Random)
        end
      end

      context 'given "defined"' do
        before do
          config.order = 'rand:123'
          config.order = 'defined'
        end

        it "does not change the seed" do
          expect(config.seed).to eq(123)
        end

        it 'clears the random ordering' do
          allow(RSpec).to receive_messages(:configuration => config)
          list = [1, 2, 3, 4]
          ordering_strategy = config.ordering_registry.fetch(:global)
          expect(ordering_strategy.order(list)).to eq([1, 2, 3, 4])
        end
      end
    end

    describe "#register_ordering" do
      def register_reverse_ordering
        config.register_ordering(:reverse, &:reverse)
      end

      it 'stores the ordering for later use' do
        register_reverse_ordering

        list = [1, 2, 3]
        strategy = config.ordering_registry.fetch(:reverse)
        expect(strategy).to be_a(Ordering::Custom)
        expect(strategy.order(list)).to eq([3, 2, 1])
      end

      it 'can register an ordering object' do
        strategy = Object.new
        def strategy.order(list)
          list.reverse
        end

        config.register_ordering(:reverse, strategy)
        list = [1, 2, 3]
        fetched = config.ordering_registry.fetch(:reverse)
        expect(fetched).to be(strategy)
        expect(fetched.order(list)).to eq([3, 2, 1])
      end
    end

    describe '#warnings' do
      around do |example|
        original_setting = $VERBOSE
        example.run
        $VERBOSE = original_setting
      end

      it "sets verbose to true when true" do
        config.warnings = true
        expect($VERBOSE).to eq true
      end

      it "sets verbose to false when true" do
        config.warnings = false
        expect($VERBOSE).to eq false
      end

      it 'returns the verbosity setting' do
        config.warnings = true
        expect(config.warnings?).to eq true

        config.warnings = false
        expect(config.warnings?).to eq false
      end

      it 'is loaded from config by #force' do
        config.force :warnings => true
        expect($VERBOSE).to eq true
      end
    end

    describe '#raise_on_warning=(value)' do
      around do |example|
        original_setting = RSpec::Support.warning_notifier
        example.run
        RSpec::Support.warning_notifier = original_setting
      end

      it 'causes warnings to raise errors when true' do
        config.raise_on_warning = true
        expect {
          RSpec.warning 'All hell breaks loose'
        }.to raise_error a_string_including('WARNING: All hell breaks loose')
      end

      it 'causes warnings to default to warning when false' do
        config.raise_on_warning = false
        expect_warning_with_call_site(__FILE__, __LINE__ + 1)
        RSpec.warning 'doesnt raise'
      end
    end

    describe "#raise_errors_for_deprecations!" do
      it 'causes deprecations to raise errors rather than printing to the deprecation stream' do
        config.deprecation_stream = stream = StringIO.new
        config.raise_errors_for_deprecations!

        expect {
          config.reporter.deprecation(:deprecated => "foo", :call_site => "foo.rb:1")
        }.to raise_error(RSpec::Core::DeprecationError, /foo is deprecated/)

        expect(stream.string).to eq("")
      end
    end

    describe "#expose_current_running_example_as" do
      before { stub_const(Configuration::ExposeCurrentExample.name, Module.new) }

      it 'exposes the current example via the named method' do
        RSpec.configuration.expose_current_running_example_as :the_example
        RSpec.configuration.expose_current_running_example_as :another_example_helper

        value_1 = value_2 = nil

        RSpec.describe "Group" do
          it "works" do
            value_1 = the_example
            value_2 = another_example_helper
          end
        end.run

        expect(value_1).to be_an(RSpec::Core::Example)
        expect(value_1.description).to eq("works")
        expect(value_2).to be(value_1)
      end
    end

    describe '#disable_monkey_patching!' do
      let!(:config) { RSpec.configuration }
      let!(:expectations) { RSpec::Expectations }
      let!(:mocks) { RSpec::Mocks }

      def in_fully_monkey_patched_rspec_environment
        in_sub_process do
          config.expose_dsl_globally = true
          mocks.configuration.syntax = [:expect, :should]
          mocks.configuration.patch_marshal_to_support_partial_doubles = true
          expectations.configuration.syntax = [:expect, :should]

          yield
        end
      end

      it 'stops exposing the DSL methods globally' do
        in_fully_monkey_patched_rspec_environment do
          mod = Module.new
          expect {
            config.disable_monkey_patching!
          }.to change { mod.respond_to?(:describe) }.from(true).to(false)
        end
      end

      it 'stops using should syntax for expectations' do
        in_fully_monkey_patched_rspec_environment do
          obj = Object.new
          config.expect_with :rspec
          expect {
            config.disable_monkey_patching!
          }.to change { obj.respond_to?(:should) }.from(true).to(false)
        end
      end

      it 'stops using should syntax for mocks' do
        in_fully_monkey_patched_rspec_environment do
          obj = Object.new
          config.mock_with :rspec
          expect {
            config.disable_monkey_patching!
          }.to change { obj.respond_to?(:should_receive) }.from(true).to(false)
        end
      end

      it 'stops patching of Marshal' do
        in_fully_monkey_patched_rspec_environment do
          expect {
            config.disable_monkey_patching!
          }.to change { Marshal.respond_to?(:dump_with_rspec_mocks) }.from(true).to(false)
        end
      end

      context 'when user did not configure mock framework' do
        def emulate_not_configured_mock_framework
          in_fully_monkey_patched_rspec_environment do
            allow(config).to receive(:rspec_mocks_loaded?).and_return(false, true)
            config.instance_variable_set :@mock_framework, nil
            ExampleGroup.send :remove_class_variable, :@@example_groups_configured

            yield
          end
        end

        it 'disables monkey patching after example groups being configured' do
          emulate_not_configured_mock_framework do
            obj = Object.new
            config.disable_monkey_patching!

            expect {
              ExampleGroup.ensure_example_groups_are_configured
            }.to change { obj.respond_to?(:should_receive) }.from(true).to(false)
          end
        end
      end

      context 'when user did not configure expectation framework' do
        def emulate_not_configured_expectation_framework
          in_fully_monkey_patched_rspec_environment do
            allow(config).to receive(:rspec_expectations_loaded?).and_return(false, true)
            config.instance_variable_set :@expectation_frameworks, []
            ExampleGroup.send :remove_class_variable, :@@example_groups_configured

            yield
          end
        end

        it 'disables monkey patching after example groups being configured' do
          emulate_not_configured_expectation_framework do
            obj = Object.new
            config.disable_monkey_patching!

            expect {
              ExampleGroup.ensure_example_groups_are_configured
            }.to change { obj.respond_to?(:should) }.from(true).to(false)
          end
        end
      end
    end

    describe 'recording spec start time (for measuring load)' do
      it 'returns a time' do
        expect(config.start_time).to be_an_instance_of ::Time
      end

      it 'is configurable' do
        config.start_time = 42
        expect(config.start_time).to eq 42
      end
    end

    describe "hooks" do
      include_examples "warning of deprecated `:example_group` during filtering configuration", :before, :each
    end

    describe '#threadsafe', :threadsafe => true do
      it 'defaults to false' do
        expect(config.threadsafe).to eq true
      end

      it 'can be configured to true or false' do
        config.threadsafe = true
        expect(config.threadsafe).to eq true

        config.threadsafe = false
        expect(config.threadsafe).to eq false
      end
    end

    describe '#max_displayed_failure_line_count' do
      it 'defaults to 10' do
        expect(config.max_displayed_failure_line_count).to eq 10
      end

      it 'is configurable' do
        config.max_displayed_failure_line_count = 5
        expect(config.max_displayed_failure_line_count).to eq 5
      end
    end

    describe '#failure_exit_code' do
      it 'defaults to 1' do
        expect(config.failure_exit_code).to eq 1
      end

      it 'is configurable' do
        config.failure_exit_code = 2
        expect(config.failure_exit_code).to eq 2
      end
    end

    describe '#error_exit_code' do
      it 'defaults to nil' do
        expect(config.error_exit_code).to eq nil
      end

      it 'is configurable' do
        config.error_exit_code = 2
        expect(config.error_exit_code).to eq 2
      end
    end

    describe "#shared_context_metadata_behavior" do
      it "defaults to :trigger_inclusion for backwards compatibility" do
        expect(config.shared_context_metadata_behavior).to eq :trigger_inclusion
      end

      it "can be set to :apply_to_host_groups" do
        config.shared_context_metadata_behavior = :apply_to_host_groups
        expect(config.shared_context_metadata_behavior).to eq :apply_to_host_groups
      end

      it "can be set to :trigger_inclusion explicitly" do
        config.shared_context_metadata_behavior = :trigger_inclusion
        expect(config.shared_context_metadata_behavior).to eq :trigger_inclusion
      end

      it "cannot be set to any other values" do
        expect {
          config.shared_context_metadata_behavior = :another_value
        }.to raise_error(ArgumentError, a_string_including(
          "shared_context_metadata_behavior",
          ":another_value", ":trigger_inclusion", ":apply_to_host_groups"
        ))
      end
    end

    # assigns files_or_directories_to_run and triggers post-processing
    # via `files_to_run`.
    def assign_files_or_directories_to_run(*value)
      config.files_or_directories_to_run = value
      config.files_to_run
    end
  end
end
