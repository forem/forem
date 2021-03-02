require 'ostruct'
require 'rspec/core/drb'

RSpec.describe RSpec::Core::ConfigurationOptions, :isolated_directory => true, :isolated_home => true do
  include ConfigOptionsHelper

  # On Ruby 2.4, `File.expand("~")` works even if `ENV['HOME']` is not set.
  # But on earlier versions, it fails.
  it "warns when HOME env var is not set", :unless => (RUBY_PLATFORM == 'java' || RSpec::Support::OS.windows? || RUBY_VERSION >= '2.4') do
    without_env_vars 'HOME' do
      expect_warning_with_call_site(__FILE__, __LINE__ + 1)
      RSpec::Core::ConfigurationOptions.new([]).options
    end
  end

  it "does not mutate the provided args array" do
    args = ['-e', 'some spec']
    RSpec::Core::ConfigurationOptions.new(args).options
    expect(args).to eq(['-e', 'some spec'])
  end

  describe "#configure" do
    let(:config) { RSpec::Core::Configuration.new }

    it "configures deprecation_stream before loading requires (since required files may issue deprecations)" do
      opts = config_options_object(*%w[--deprecation-out path/to/log --require foo])
      configuration = instance_double(RSpec::Core::Configuration).as_null_object

      opts.configure(configuration)

      expect(configuration).to have_received(:force).with(:deprecation_stream => "path/to/log").ordered
      expect(configuration).to have_received(:requires=).ordered
    end

    it "configures deprecation_stream before configuring filter_manager" do
      opts = config_options_object(*%w[--deprecation-out path/to/log --tag foo])
      filter_manager = instance_double(RSpec::Core::FilterManager).as_null_object
      configuration = instance_double(RSpec::Core::Configuration, :filter_manager => filter_manager).as_null_object

      opts.configure(configuration)

      expect(configuration).to have_received(:force).with(:deprecation_stream => "path/to/log").ordered
      expect(filter_manager).to have_received(:include).with(:foo => true).ordered
    end

    it "configures deprecation_stream before configuring formatters" do
      opts = config_options_object(*%w[--deprecation-out path/to/log --format doc])
      configuration = instance_double(RSpec::Core::Configuration).as_null_object

      opts.configure(configuration)

      expect(configuration).to have_received(:force).with(:deprecation_stream => "path/to/log").ordered
      expect(configuration).to have_received(:add_formatter).ordered
    end

    it "sends libs before requires" do
      opts = config_options_object(*%w[--require a/path -I a/lib])
      configuration = double("config").as_null_object
      expect(configuration).to receive(:libs=).ordered
      expect(configuration).to receive(:requires=).ordered
      opts.configure(configuration)
    end

    it "loads requires before loading specs" do
      opts = config_options_object(*%w[-rspec_helper])
      expect(config).to receive(:requires=).ordered
      expect(config).to receive(:get_files_to_run).ordered
      opts.configure(config)
      config.files_to_run
    end

    it "sets up load path and requires before formatter" do
      opts = config_options_object(*%w[--require a/path -f a/formatter])
      configuration = double("config").as_null_object
      expect(configuration).to receive(:requires=).ordered
      expect(configuration).to receive(:add_formatter).ordered
      opts.configure(configuration)
    end

    it "sets default_path before loading specs" do
      opts = config_options_object(*%w[--default-path spec])
      expect(config).to receive(:force).with(:default_path => 'spec').ordered
      expect(config).to receive(:get_files_to_run).ordered
      opts.configure(config)
      config.files_to_run
    end

    it "sets `files_or_directories_to_run` before `requires` so users can check `files_to_run` in a spec_helper loaded by `--require`" do
      opts = config_options_object(*%w[--require spec_helper])
      expect(config).to receive(:files_or_directories_to_run=).ordered
      expect(config).to receive(:requires=).ordered
      opts.configure(config)
    end

    it "sets default_path before `files_or_directories_to_run` since it relies on it" do
      opts = config_options_object(*%w[--default-path spec])
      expect(config).to receive(:force).with(:default_path => 'spec').ordered
      expect(config).to receive(:files_or_directories_to_run=).ordered
      opts.configure(config)
    end

    it 'configures the seed (via `order`) before requires so that required files can use the configured seed' do
      opts = config_options_object(*%w[ --seed 1234 --require spec_helper ])

      expect(config).to receive(:force).with(:order => "rand:1234").ordered
      expect(config).to receive(:requires=).ordered

      opts.configure(config)
    end

    it 'configures `only_failures` before `files_or_directories_to_run` since it affects loaded files' do
      opts = config_options_object(*%w[ --only-failures ])
      expect(config).to receive(:force).with(:only_failures => true).ordered
      expect(config).to receive(:files_or_directories_to_run=).ordered
      opts.configure(config)
    end

    { "pattern" => :pattern, "exclude-pattern" => :exclude_pattern }.each do |flag, attr|
      it "sets #{attr} before `requires` so users can check `files_to_run` in a `spec_helper` loaded by `--require`" do
        opts = config_options_object(*%W[--require spec_helpe --#{flag} **/*.spec])
        expect(config).to receive(:force).with(attr => '**/*.spec').ordered
        expect(config).to receive(:requires=).ordered
        opts.configure(config)
      end
    end

    it "assigns inclusion_filter" do
      opts = config_options_object(*%w[--tag awesome])
      opts.configure(config)
      expect(config.inclusion_filter.rules).to have_key(:awesome)
    end

    it "merges the :exclusion_filter option with the default exclusion_filter" do
      opts = config_options_object(*%w[--tag ~slow])
      opts.configure(config)
      expect(config.exclusion_filter.rules).to have_key(:slow)
    end

    it "forces color" do
      opts = config_options_object(*%w[--color])
      expect(config).to receive(:force).with(:color => true)
      expect(config).to receive(:force).with(:color_mode => :automatic)
      opts.configure(config)
    end

    it "forces force_color" do
      opts = config_options_object(*%w[--force-color])
      expect(config).to receive(:force).with(:color_mode => :on)
      opts.configure(config)
    end

    it "forces no_color" do
      opts = config_options_object(*%w[--no-color])
      expect(config).to receive(:force).with(:color_mode => :off)
      opts.configure(config)
    end

    [
      ["--failure-exit-code", "3", :failure_exit_code, 3 ],
      ["--pattern", "foo/bar", :pattern, "foo/bar"],
      ["--failure-exit-code", "37", :failure_exit_code, 37],
      ["--default-path", "behavior", :default_path, "behavior"],
      ["--order", "rand", :order, "rand"],
      ["--seed", "37", :order, "rand:37"],
      ["--drb-port", "37", :drb_port, 37]
    ].each do |cli_option, cli_value, config_key, config_value|
      it "forces #{config_key}" do
        opts = config_options_object(cli_option, cli_value)
        expect(config).to receive(:force) do |pair|
          expect(pair.keys.first).to eq(config_key)
          expect(pair.values.first).to eq(config_value)
        end
        opts.configure(config)
      end
    end

    it "merges --require specified by multiple configuration sources" do
      with_env_vars 'SPEC_OPTS' => "--require file_from_env" do
        opts = config_options_object(*%w[--require file_from_opts])
        expect(config).to receive(:require).with("file_from_opts")
        expect(config).to receive(:require).with("file_from_env")
        opts.configure(config)
      end
    end

    it "merges --I specified by multiple configuration sources" do
      with_env_vars 'SPEC_OPTS' => "-I dir_from_env" do
        opts = config_options_object(*%w[-I dir_from_opts])
        expect(config).to receive(:libs=).with(["dir_from_opts", "dir_from_env"])
        opts.configure(config)
      end
    end

    %w[ --only-failures --next-failure -n].each do |option|
      describe option do
        it "changes `config.only_failures?` to true" do
          opts = config_options_object(option)

          expect {
            opts.configure(config)
          }.to change(config, :only_failures?).from(a_falsey_value).to(true)
        end
      end
    end
  end

  describe "-c, --color, and --colour" do
    it "sets :color_mode => :automatic" do
      expect(parse_options('-c')).to include(:color_mode => :automatic)
      expect(parse_options('--color')).to include(:color_mode => :automatic)
      expect(parse_options('--colour')).to include(:color_mode => :automatic)
    end

    it "overrides previous color flag" do
      expect(parse_options('--no-color', '--color')).to include(:color_mode => :automatic)
    end
  end

  describe "--no-color" do
    it "sets :color_mode => :off" do
      expect(parse_options('--no-color')).to include(:color_mode => :off)
    end

    it "overrides previous color flag" do
      expect(parse_options('--color', '--no-color')).to include(:color_mode => :off)
    end
  end

  describe "--force-color" do
    it "sets :color_mode => :on" do
      expect(parse_options('--force-color')).to include(:color_mode => :on)
    end

    it "overrides previous color flag" do
      expect(parse_options('--color', '--force-color')).to include(:color_mode => :on)
    end
  end

  describe "-I" do
    example "adds to :libs" do
      expect(parse_options('-I', 'a_dir')).to include(:libs => ['a_dir'])
    end
    example "can be used more than once" do
      expect(parse_options('-I', 'dir_1', '-I', 'dir_2')).to include(:libs => ['dir_1','dir_2'])
    end
  end

  describe '--require' do
    example "requires files" do
      expect(parse_options('--require', 'a/path')).to include(:requires => ['a/path'])
    end
    example "can be used more than once" do
      expect(parse_options('--require', 'path/1', '--require', 'path/2')).to include(:requires => ['path/1','path/2'])
    end
  end

  describe "--format, -f" do
    it "sets :formatter" do
      [['--format', 'd'], ['-f', 'd'], '-fd'].each do |args|
        expect(parse_options(*args)).to include(:formatters => [['d']])
      end
    end

    example "can accept a class name" do
      expect(parse_options('-fSome::Formatter::Class')).to include(:formatters => [['Some::Formatter::Class']])
    end
  end

  describe "--profile, -p" do
    it "sets :profile_examples" do
      expect(parse_options('-p')).to include(:profile_examples => true)
      expect(parse_options('--profile')).to include(:profile_examples => true)
      expect(parse_options('-p', '4')).to include(:profile_examples => 4)
      expect(parse_options('--profile', '3')).to include(:profile_examples => 3)
    end
  end

  describe "--no-profile" do
    it "sets :profile_examples to false" do
      expect(parse_options('--no-profile')).to include(:profile_examples => false)
    end
  end

  describe "--example" do
    it "sets :full_description" do
      expect(parse_options('--example','foo')).to include(:full_description => [/foo/])
      expect(parse_options('-e','bar')).to include(:full_description => [/bar/])
    end
  end

  describe "--backtrace, -b" do
    it "sets full_backtrace on config" do
      expect(parse_options("--backtrace")).to include(:full_backtrace => true)
      expect(parse_options("-b")).to include(:full_backtrace => true)
    end
  end

  describe "--fail-fast" do
    it "defaults to nil" do
      expect(parse_options[:fail_fast]).to be(nil)
    end

    it "sets fail_fast to 1 on config" do
      expect(parse_options("--fail-fast")[:fail_fast]).to be(1)
    end

    it "sets fail_fast to false on config" do
      expect(parse_options("--no-fail-fast")[:fail_fast]).to be(false)
    end
  end

  describe "--failure-exit-code" do
    it "sets :failure_exit_code" do
      expect(parse_options('--failure-exit-code', '0')).to include(:failure_exit_code => 0)
      expect(parse_options('--failure-exit-code', '1')).to include(:failure_exit_code => 1)
      expect(parse_options('--failure-exit-code', '2')).to include(:failure_exit_code => 2)
    end

    it "overrides previous :failure_exit_code" do
      expect(parse_options('--failure-exit-code', '2', '--failure-exit-code', '3')).to include(:failure_exit_code => 3)
    end
  end

  describe "--error-exit-code" do
    it "sets :error_exit_code" do
      expect(parse_options('--error-exit-code', '0')).to include(:error_exit_code => 0)
      expect(parse_options('--error-exit-code', '1')).to include(:error_exit_code => 1)
      expect(parse_options('--error-exit-code', '2')).to include(:error_exit_code => 2)
    end

    it "overrides previous :error_exit_code" do
      expect(parse_options('--error-exit-code', '2', '--error-exit-code', '3')).to include(:error_exit_code => 3)
    end
  end

  describe "--dry-run" do
    it "defaults to nil" do
      expect(parse_options[:dry_run]).to be(nil)
    end

    it "sets dry_run on config" do
      expect(parse_options("--dry-run")[:dry_run]).to be(true)
    end
  end

  describe "--options" do
    it "sets :custom_options_file" do
      expect(parse_options(*%w[-O my.opts])).to include(:custom_options_file => "my.opts")
      expect(parse_options(*%w[--options my.opts])).to include(:custom_options_file => "my.opts")
    end
  end

  describe "--no-drb" do
    it "disables drb" do
      expect(parse_options("--no-drb")).to include(:drb => false)
    end

    it "overrides a previous drb => true" do
      expect(parse_options("--drb", "--no-drb")).to include(:drb => false)
    end

    it "gets overriden by a subsquent drb => true" do
      expect(parse_options("--no-drb", "--drb")).to include(:drb => true)
    end
  end

  describe "files_or_directories_to_run" do
    it "parses files from '-c file.rb dir/file.rb'" do
      expect(parse_options("-c", "file.rb", "dir/file.rb")).to include(
        :files_or_directories_to_run => ["file.rb", "dir/file.rb"]
      )
    end

    it "parses dir from 'dir'" do
      expect(parse_options("dir")).to include(:files_or_directories_to_run => ["dir"])
    end

    it "parses dir and files from 'spec/file1_spec.rb, spec/file2_spec.rb'" do
      expect(parse_options("dir", "spec/file1_spec.rb", "spec/file2_spec.rb")).to include(
        :files_or_directories_to_run => ["dir", "spec/file1_spec.rb", "spec/file2_spec.rb"]
      )
    end

    it "parses file names that look like `default-path` option" do
      expect(parse_options("spec/default_path_spec.rb")).to include(
        :files_or_directories_to_run => ["spec/default_path_spec.rb"]
      )
    end

    it "provides no files or directories if spec directory does not exist" do
      allow(FileTest).to receive(:directory?).with("spec").and_return false
      expect(parse_options()).to include(:files_or_directories_to_run => [])
    end
  end

  describe "default_path" do
    it "gets set before files_or_directories_to_run" do
      config = RSpec::Core::Configuration.new
      expect(config).to receive(:force).with(:default_path => 'foo').ordered
      expect(config).to receive(:get_files_to_run).ordered
      opts = config_options_object("--default-path", "foo")
      opts.configure(config)
      config.files_to_run
    end
  end

  describe "invalid options" do
    def expect_parsing_to_fail_mentioning_source(source, options=[])
      expect {
        parse_options(*options)
      }.to raise_error(SystemExit).and output(a_string_including(
        "invalid option: --foo_bar (defined in #{source})",
        "Please use --help for a listing of valid options"
      )).to_stderr
    end

    %w[ ~/.rspec ./.rspec ./.rspec-local ].each do |file_name|
      context "defined in #{file_name}" do
        it "mentions the file name in the error so users know where to look for it" do
          file_name = File.expand_path(file_name) if file_name.start_with?("~")
          File.open(File.expand_path(file_name), "w") { |f| f << "--foo_bar" }
          expect_parsing_to_fail_mentioning_source(file_name)
        end
      end
    end

    context "defined in $XDG_CONFIG_HOME/rspec/options" do
      it "mentions the file name in the error so users know where to look for it" do
        file_name = File.expand_path("~/.config/rspec/options")
        create_fixture_file(file_name, "--foo_bar")
        expect_parsing_to_fail_mentioning_source(file_name)
      end
    end

    context "defined in SPEC_OPTS" do
      it "mentions ENV['SPEC_OPTS'] as the source in the error so users know where to look for it" do
        with_env_vars 'SPEC_OPTS' => "--foo_bar" do
          expect_parsing_to_fail_mentioning_source("ENV['SPEC_OPTS']")
        end
      end
    end

    context "defined in a custom file" do
      it "mentions the custom file as the source of the error so users know where to look for it" do
        File.open("./custom.opts", "w") {|f| f << "--foo_bar"}

        expect_parsing_to_fail_mentioning_source("./custom.opts", %w[-O ./custom.opts])
      end

      context "passed at the command line" do
        it "does not mention the source since it is obvious where it came from" do
          expect {
            parse_options("--foo_bar")
          }.to raise_error(SystemExit).and output(a_string_including(
            "invalid option: --foo_bar\n",
            "Please use --help for a listing of valid options"
          )).to_stderr
        end
      end
    end
  end

  describe "sources: $XDG_CONFIG_HOME/rspec/options, ~/.rspec, ./.rspec, ./.rspec-local, custom, CLI, and SPEC_OPTS" do
    it "merges both global, local, SPEC_OPTS, and CLI" do
      create_fixture_file("./.rspec", "--require some_file")
      create_fixture_file("./.rspec-local", "--format global")
      create_fixture_file("~/.rspec", "--force-color")
      create_fixture_file("~/.config/rspec/options", "--order defined")
      with_env_vars 'SPEC_OPTS' => "--example 'foo bar'" do
        options = parse_options("--drb")
        # $XDG_CONFIG_HOME/rspec/options file ("order") is read, but ~/.rspec
        # file ("color") is not read because ~/.rspec has lower priority over
        # the file in the XDG config directory.
        expect(options[:order]).to eq("defined")
        expect(options[:color_mode]).to be_nil

        expect(options[:requires]).to eq(["some_file"])
        expect(options[:full_description]).to eq([/foo\ bar/])
        expect(options[:drb]).to be(true)
        expect(options[:formatters]).to eq([['global']])
      end
    end

    it "reads ~/.rspec if $XDG_CONFIG_HOME/rspec/options is not found" do
      create_fixture_file("~/.rspec", "--force-color")

      options = parse_options()
      expect(options[:color_mode]).to eq(:on)
      expect(options[:order]).to be_nil
    end

    it "does not read ~/.rspec if $XDG_CONFIG_HOME/rspec/options is present" do
      create_fixture_file("~/.rspec", "--force-color")
      create_fixture_file("~/.config/rspec/options", "--order defined")

      options = parse_options()
      expect(options[:color_mode]).to be_nil
      expect(options[:order]).to eq("defined")
    end

    it "uses $XDG_CONFIG_HOME environment variable when set to find XDG global options" do
      create_fixture_file("~/.config/rspec/options", "--format default_xdg")
      create_fixture_file("~/.custom-config/rspec/options", "--format overridden_xdg")

      with_env_vars 'XDG_CONFIG_HOME' => "~/.custom-config" do
        options = parse_options()
        expect(options[:formatters]).to eq([['overridden_xdg']])
      end

      without_env_vars 'XDG_CONFIG_HOME' do
        options = parse_options()
        expect(options[:formatters]).to eq([['default_xdg']])
      end
    end

    it 'ignores file or dir names put in one of the option files or in SPEC_OPTS, since those are for persistent options' do
      create_fixture_file("./.rspec", "path/to/spec_1.rb" )
      create_fixture_file("./.rspec-local", "path/to/spec_2.rb" )
      create_fixture_file("~/.rspec", "path/to/spec_3.rb")
      create_fixture_file("~/.config/rspec/options", "path/to/spec_4.rb")
      with_env_vars 'SPEC_OPTS' => "path/to/spec_4.rb" do
        options = parse_options()
        expect(options[:files_or_directories_to_run]).to eq([])
      end
    end

    it "prefers SPEC_OPTS over CLI" do
      with_env_vars 'SPEC_OPTS' => "--format spec_opts" do
        expect(parse_options("--format", "cli")[:formatters]).to eq([['spec_opts']])
      end
    end

    it "prefers CLI over file options" do
      create_fixture_file("./.rspec", "--format project")
      create_fixture_file("~/.rspec", "--format global")
      create_fixture_file("~/.config/rspec/options", "--format xdg")
      expect(parse_options("--format", "cli")[:formatters]).to eq([['cli']])
    end

    it "prefers CLI over file options for filter inclusion" do
      create_fixture_file("./.rspec", "--tag ~slow")
      opts = config_options_object("--tag", "slow")
      config = RSpec::Core::Configuration.new
      opts.configure(config)
      expect(config.inclusion_filter.rules).to have_key(:slow)
      expect(config.exclusion_filter.rules).not_to have_key(:slow)
    end

    it "prefers project file options over global file options" do
      create_fixture_file("./.rspec", "--format project")
      create_fixture_file("~/.rspec", "--format global")
      create_fixture_file("~/.config/rspec/options", "--format xdg")
      expect(parse_options[:formatters]).to eq([['project']])
    end

    it "prefers local file options over project file options" do
      create_fixture_file("./.rspec-local", "--format local")
      create_fixture_file("./.rspec", "--format global")
      expect(parse_options[:formatters]).to eq([['local']])
    end

    it "parses options file correctly if erb code has trimming options" do
      File.open("./.rspec", "w") do |f|
        f << "<% if true -%>\n"
        f << "--format local\n"
        f << "<%- end %>\n"
      end

      expect(parse_options[:formatters]).to eq([['local']])
    end

    context "with custom options file" do
      it "ignores project and global options files" do
        create_fixture_file("./.rspec", "--format project")
        create_fixture_file("~/.rspec", "--format global")
        create_fixture_file("~/.config/rspec/options", "--format xdg")
        create_fixture_file("./custom.opts", "--force-color")
        options = parse_options("-O", "./custom.opts")
        expect(options[:format]).to be_nil
        expect(options[:color_mode]).to eq(:on)
      end

      it "parses -e 'full spec description'" do
        create_fixture_file("./custom.opts", "-e 'The quick brown fox jumps over the lazy dog'")
        options = parse_options("-O", "./custom.opts")
        expect(options[:full_description]).to eq([/The\ quick\ brown\ fox\ jumps\ over\ the\ lazy\ dog/])
      end
    end
  end
end
