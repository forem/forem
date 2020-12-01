require 'rspec/support/spec/library_wide_checks'

RSpec.describe RSpec do
  fake_libs = File.expand_path('../../support/fake_libs', __FILE__)
  allowed_loaded_features = [
    /optparse\.rb/,   # Used by OptionParser.
    /rbconfig\.rb/,   # loaded by rspec-support for OS detection.
    /shellwords\.rb/, # used by ConfigurationOptions and RakeTask.
    /stringio/,       # Used by BaseFormatter.
    %r{/fake_libs/},  # ignore these, obviously
  ]

  # JRuby appears to not respect `--disable=gem` so rubygems also gets loaded.
  allowed_loaded_features << /rubygems/ if RSpec::Support::Ruby.jruby?

  disable_autorun_code =
    if RSpec::Support::OS.windows?
      # On Windows, the "redefine autorun" approach results in a different
      # exit status for a reason I don't understand, so we just disable
      # autorun outright.
      'RSpec::Core::Runner.disable_autorun!'
    else
      # On JRuby, the `disable_autorun!` approach leads to a stderr warning
      # related to a deprecation emited when `rspec/core/autorun` gets loaded,
      # because of `caller_filter` issues, so we redefine the autorun method
      # instead. That works fine on all Rubies when we're not on Windows as
      # well.
      'RSpec::Core::Runner.instance_exec { undef :autorun; def autorun; end }'
    end

  it_behaves_like 'library wide checks', 'rspec-core',
    :preamble_for_lib => [
      # rspec-core loads a number of external libraries. We don't want them loaded
      # as part of loading all of rspec-core for these specs, for a few reasons:
      #
      #   * Some external libraries issue warnings, which we can't do anything about.
      #     Since we are trying to prevent _any_ warnings from loading RSpec, it's
      #     easiest to avoid loading those libraries entirely.
      #   * Some external libraries load many stdlibs. Here we allow a known set of
      #     directly loaded stdlibs, and we're not directly concerned with transitive
      #     dependencies.
      #   * We're really only concerned with these issues w.r.t. rspec-mocks and
      #     rspec-expectations from within their spec suites. Here we care only about
      #     rspec-core, so avoiding loading them helps keep the spec suites independent.
      #   * These are some of the slowest specs we have, and cutting out the loading
      #     of external libraries cuts down on how long these specs take.
      #
      # To facilitate the avoidance of loading certain libraries, we have a bunch
      # of files in `support/fake_libs` that substitute for the real things when
      # we put that directory on the load path. Here's the list:
      #
      #   * coderay -- loaded by the HTML formatter if availble for syntax highlighting.
      #   * drb -- loaded when `--drb` is used. Loads other stdlibs (socket, thread, fcntl).
      #   * erb -- loaded by `ConfigurationOptions` so `.rspec` can use ERB. Loads other stdlibs (strscan, cgi/util).
      #   * flexmock -- loaded by our Flexmock mocking adapter.
      #   * json -- loaded by the JSON formatter, loads other stdlibs (ostruct, enc/utf_16le.bundle, etc).
      #   * minitest -- loaded by our Minitest assertions adapter.
      #   * mocha -- loaded by our Mocha mocking adapter.
      #   * rake -- loaded by our Rake task. Loads other stdlibs (fileutils, ostruct, thread, monitor, etc).
      #   * rr -- loaded by our RR mocking adapter.
      #   * rspec-mocks -- loaded by our RSpec mocking adapter.
      #   * rspec-expectations -- loaded by the generated `spec_helper` (defined in project_init).
      #   * test-unit -- loaded by our T::U assertions adapter.
      #
      "$LOAD_PATH.unshift '#{fake_libs}'",
      # Many files assume this has already been loaded and will have errors if it has not.
      'require "rspec/core"',
      # Prevent rspec/autorun from trying to run RSpec.
      disable_autorun_code
    ], :skip_spec_files => %r{/fake_libs/}, :allowed_loaded_feature_regexps => allowed_loaded_features do
    if RUBY_VERSION == '1.8.7'
      before(:example, :description => /(issues no warnings when the spec files are loaded|stdlibs)/) do
        pending "Not working on #{RUBY_DESCRIPTION}"
      end
    elsif RUBY_VERSION == '2.0.0' && RSpec::Support::Ruby.jruby?
      before(:example) do
        skip "Not reliably working on #{RUBY_DESCRIPTION}"
      end
    end
  end

  describe ".configuration" do
    it "returns the same object every time" do
      expect(RSpec.configuration).to equal(RSpec.configuration)
    end
  end

  describe ".configuration=" do
    it "sets the configuration object" do
      configuration = RSpec::Core::Configuration.new

      RSpec.configuration = configuration

      expect(RSpec.configuration).to equal(configuration)
    end
  end

  describe ".configure" do
    it "yields the current configuration" do
      RSpec.configure do |config|
        expect(config).to equal(RSpec::configuration)
      end
    end
  end

  describe ".world" do
    it "returns the same object every time" do
      expect(RSpec.world).to equal(RSpec.world)
    end
  end

  describe ".world=" do
    it "sets the world object" do
      world = RSpec::Core::World.new

      RSpec.world = world

      expect(RSpec.world).to equal(world)
    end
  end

  describe ".current_example" do
    it "sets the example being executed" do
      group = RSpec.describe("an example group")
      example = group.example("an example")

      RSpec.current_example = example
      expect(RSpec.current_example).to be(example)
    end
  end

  describe ".reset" do
    it "resets the configuration and world objects" do
      config_before_reset = RSpec.configuration
      world_before_reset  = RSpec.world

      RSpec.reset

      expect(RSpec.configuration).not_to equal(config_before_reset)
      expect(RSpec.world).not_to equal(world_before_reset)
    end

    it 'removes the previously assigned example group constants' do
        RSpec.describe "group"

        expect {
          RSpec.world.reset
        }.to change(RSpec::ExampleGroups, :constants).to([])
    end
  end

  describe ".clear_examples" do
    let(:listener) { double("listener") }

    def reporter
      RSpec.configuration.reporter
    end

    before do
      RSpec.configuration.output_stream = StringIO.new
      RSpec.configuration.error_stream = StringIO.new
    end

    it "clears example groups" do
      RSpec.world.example_groups << :example_group

      RSpec.clear_examples

      expect(RSpec.world.example_groups).to be_empty
    end

    it "resets start_time" do
      start_time_before_clear = RSpec.configuration.start_time

      RSpec.clear_examples

      expect(RSpec.configuration.start_time).not_to eq(start_time_before_clear)
    end

    it "clears examples, failed_examples and pending_examples" do
      reporter.start(3)
      pending_ex = failing_ex = nil

      RSpec.describe do
        pending_ex = pending { fail }
        failing_ex = example { fail }
      end.run

      reporter.example_started(failing_ex)
      reporter.example_failed(failing_ex)

      reporter.example_started(pending_ex)
      reporter.example_pending(pending_ex)
      reporter.finish

      RSpec.clear_examples

      reporter.register_listener(listener, :dump_summary)

      expect(listener).to receive(:dump_summary) do |notification|
        expect(notification.examples).to be_empty
        expect(notification.failed_examples).to be_empty
        expect(notification.pending_examples).to be_empty
      end

      reporter.start(0)
      reporter.finish
    end

    it "restores inclusion rules set by configuration" do
      file_path = File.expand_path("foo_spec.rb")
      RSpec.configure do |config|
        config.filter_run_including(:locations => { file_path => [12] })
      end
      allow(RSpec.configuration).to receive(:load).with(file_path)
      allow(reporter).to receive(:report)
      RSpec::Core::Runner.run(["foo_spec.rb:14"])

      expect(
        RSpec.configuration.filter_manager.inclusions[:locations]
      ).to eq(file_path => [12, 14])

      RSpec.clear_examples

      expect(
        RSpec.configuration.filter_manager.inclusions[:locations]
      ).to eq(file_path => [12])
    end

    it "restores exclusion rules set by configuration" do
      RSpec.configure { |config| config.filter_run_excluding(:slow => true) }
      allow(RSpec.configuration).to receive(:load)
      allow(reporter).to receive(:report)
      RSpec::Core::Runner.run(["--tag", "~fast"])

      expect(
        RSpec.configuration.filter_manager.exclusions.rules
      ).to eq(:slow => true, :fast => true)

      RSpec.clear_examples

      expect(
        RSpec.configuration.filter_manager.exclusions.rules
      ).to eq(:slow => true)
    end

    it 'clears the deprecation buffer' do
      RSpec.configuration.deprecation_stream = StringIO.new

      RSpec.describe do
        example { RSpec.deprecate("first deprecation") }
      end.run

      reporter.start(1)
      reporter.finish

      RSpec.clear_examples

      RSpec.configuration.deprecation_stream = StringIO.new(deprecations = "".dup)

      RSpec.describe do
        example { RSpec.deprecate("second deprecation") }
      end.run

      reporter.start(1)
      reporter.finish

      expect(deprecations).to     include("second deprecation")
      expect(deprecations).to_not include("first deprecation")
    end

    it 'does not clear shared examples' do
      RSpec.shared_examples_for("shared") { }

      RSpec.clear_examples

      registry = RSpec.world.shared_example_group_registry
      expect(registry.find([:main], "shared")).to_not be_nil
    end
  end

  it 'uses only one thread local variable', :run_last do
    # Trigger features that use thread locals...
    aggregate_failures { }
    RSpec.shared_examples_for("something") { }

    expect(Thread.current.keys.map(&:to_s).grep(/rspec/i).count).to eq(1)
  end

  describe "::Core.path_to_executable" do
    it 'returns the absolute location of the exe/rspec file' do
      expect(File.exist? RSpec::Core.path_to_executable).to be(true)
      expect(File.read(RSpec::Core.path_to_executable)).to include("RSpec::Core::Runner.invoke")
      expect(File.executable? RSpec::Core.path_to_executable).to be(true) unless RSpec::Support::OS.windows?
    end
  end

  include RSpec::Support::ShellOut

  # This is hard to test :(. Best way I could come up with was starting
  # fresh ruby process w/o this stuff already loaded.
  it "loads mocks and expectations when the constants are referenced", :slow do
    code = 'require "rspec"; puts RSpec::Mocks.name; puts RSpec::Expectations.name'
    out, err, status = run_ruby_with_current_load_path(code)

    expect(err).to eq("")
    expect(out.split("\n")).to eq(%w[ RSpec::Mocks RSpec::Expectations ])
    expect(status.exitstatus).to eq(0)

    expect(RSpec.const_missing(:Expectations)).to be(RSpec::Expectations)
  end

  it 'correctly raises an error when an invalid const is referenced' do
    expect {
      RSpec::NotAConst
    }.to raise_error(NameError, /RSpec::NotAConst/)
  end

  it "does not blow up if some gem defines `Kernel#it`", :slow do
    code = 'Kernel.module_eval { def it(*); end }; require "rspec/core"'
    out, err, status = run_ruby_with_current_load_path(code)

    expect(err).to eq("")
    expect(out).to eq("")
    expect(status.exitstatus).to eq(0)
  end
end

