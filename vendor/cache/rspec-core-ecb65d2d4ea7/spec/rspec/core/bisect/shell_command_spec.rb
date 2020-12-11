require 'rspec/core/bisect/shell_command'
require 'rspec/core/formatters/bisect_drb_formatter'

module RSpec::Core
  RSpec.describe Bisect::ShellCommand do
    let(:server) { instance_double("RSpec::Core::Bisect::Server", :drb_port => 1234) }
    let(:shell_command) { described_class.new(original_cli_args) }

    describe "#command_for" do
      def command_for(locations, options={})
        load_path = options.fetch(:load_path) { [] }
        orig_load_path = $LOAD_PATH.dup
        $LOAD_PATH.replace(load_path)
        shell_command.command_for(locations, server)
      ensure
        $LOAD_PATH.replace(orig_load_path)
      end

      let(:original_cli_args) { %w[ spec/unit -rfoo -Ibar --warnings --backtrace ] }

      it "includes the original CLI arg options" do
        cmd = command_for(%w[ spec/1.rb spec/2.rb ])
        expect(cmd).to include("-rfoo -Ibar --warnings --backtrace")
      end

      it 'replaces the locations from the original CLI args with the provided locations' do
        cmd = command_for(%w[ spec/1.rb spec/2.rb ])
        expect(cmd).to match(%r{'?spec/1\.rb'? '?spec/2\.rb'?}).and exclude("spec/unit")
      end

      it 'escapes locations' do
        cmd = command_for(["path/with spaces/to/spec.rb"])
        if uses_quoting_for_escaping?
          expect(cmd).to include("'path/with spaces/to/spec.rb'")
        else
          expect(cmd).to include('path/with\ spaces/to/spec.rb')
        end
      end

      it "includes an option for the server's DRB port" do
        cmd = command_for([])
        expect(cmd).to include("--drb-port #{server.drb_port}")
      end

      it "ignores an existing --drb-port option (since we use the server's port instead)" do
        original_cli_args << "--drb-port" << "9999"
        cmd = command_for([])
        expect(cmd).to include("--drb-port #{server.drb_port}").and exclude("9999")
        expect(cmd.scan("--drb-port").count).to eq(1)
      end

      %w[ --bisect --bisect=verbose --bisect=blah ].each do |value|
        it "ignores a `#{value}` option since that would infinitely recurse" do
          original_cli_args << value
          cmd = command_for([])
          expect(cmd).to exclude(value)
        end
      end

      it 'uses the bisect formatter' do
        cmd = command_for([])
        expect(cmd).to include("--format bisect")
      end

      def expect_formatters_to_be_excluded
        cmd = command_for([])
        expect(cmd).to include("--format bisect").and exclude(
          "progress", "html", "--out", "specs.html", "-f ", "-o "
        )
        expect(cmd.scan("--format").count).to eq(1)
      end

      it 'excludes any --format and matching --out options passed in the original args' do
        original_cli_args.concat %w[ --format progress --format html --out specs.html ]
        expect_formatters_to_be_excluded
      end

      it 'excludes any -f <value> and matching -o <value> options passed in the original args' do
        original_cli_args.concat %w[ -f progress -f html -o specs.html ]
        expect_formatters_to_be_excluded
      end

      it 'excludes any -f<value> and matching -o<value> options passed in the original args' do
        original_cli_args.concat %w[ -fprogress -fhtml -ospecs.html ]
        expect_formatters_to_be_excluded
      end

      it 'starts with the path to the current ruby executable' do
        cmd = command_for([])
        expect(cmd).to start_with(File.join(
          RbConfig::CONFIG['bindir'],
          RbConfig::CONFIG['ruby_install_name']
        ))
      end

      it 'includes the path to the rspec executable after the ruby executable' do
        cmd = command_for([])
        expect(cmd).to first_include("ruby").then_include(RSpec::Core.path_to_executable)
      end

      it 'escapes the rspec executable' do
        allow(RSpec::Core).to receive(:path_to_executable).and_return("path/with spaces/rspec")
        cmd = command_for([])

        if uses_quoting_for_escaping?
          expect(cmd).to include("'path/with spaces/rspec'")
        else
          expect(cmd).to include('path/with\ spaces/rspec')
        end
      end

      it 'includes the current load path as an option to `ruby`, not as an option to `rspec`' do
        cmd = command_for([], :load_path => %W[ lp/foo lp/bar ])
        if uses_quoting_for_escaping?
          expect(cmd).to first_include("-I'lp/foo':'lp/bar'").then_include(RSpec::Core.path_to_executable)
        else
          expect(cmd).to first_include("-Ilp/foo:lp/bar").then_include(RSpec::Core.path_to_executable)
        end
      end

      it 'escapes the load path entries' do
        cmd = command_for([], :load_path => ['l p/foo', 'l p/bar' ])
        if uses_quoting_for_escaping?
          expect(cmd).to first_include("-I'l p/foo':'l p/bar'").then_include(RSpec::Core.path_to_executable)
        else
          expect(cmd).to first_include('-Il\ p/foo:l\ p/bar').then_include(RSpec::Core.path_to_executable)
        end
      end

      it 'supports Pathnames in the load path' do
        cmd = command_for([], :load_path => [Pathname('l p/foo'), Pathname('l p/bar') ])
        if uses_quoting_for_escaping?
          expect(cmd).to first_include("-I'l p/foo':'l p/bar'").then_include(RSpec::Core.path_to_executable)
        else
          expect(cmd).to first_include('-Il\ p/foo:l\ p/bar').then_include(RSpec::Core.path_to_executable)
        end
      end
    end

    describe "#repro_command_from", :simulate_shell_allowing_unquoted_ids do
      let(:original_cli_args) { %w[ spec/unit --seed 1234 ] }

      def repro_command_from(ids)
        shell_command.repro_command_from(ids)
      end

      it 'starts with `rspec #{example_ids}`' do
        cmd = repro_command_from(%w[ ./spec/unit/1_spec.rb[1:1] ./spec/unit/2_spec.rb[1:1] ])
        expect(cmd).to start_with("rspec ./spec/unit/1_spec.rb[1:1] ./spec/unit/2_spec.rb[1:1]")
      end

      it 'includes the original CLI args but excludes the original CLI locations' do
        cmd = repro_command_from(%w[ ./spec/unit/1_spec.rb[1:1] ./spec/unit/2_spec.rb[1:1] ])
        expect(cmd).to include("--seed 1234").and exclude("spec/unit ")
      end

      it 'includes the original SPEC_OPTS but excludes the --bisect flag' do
        with_env_vars('SPEC_OPTS' => '--bisect --seed 1234') do
          cmd = repro_command_from(%w[ ./spec/unit/1_spec.rb[1:1] ])
          expect(cmd).to include('SPEC_OPTS="--seed 1234"').and exclude("--bisect")
        end
      end

      it 'includes original options that `command_for` excludes' do
        original_cli_args << "--format" << "progress"
        expect(shell_command.command_for(%w[ ./foo.rb[1:1] ], server)).to exclude("--format progress")
        expect(repro_command_from(%w[ ./foo.rb[1:1] ])).to include("--format progress")
      end

      it 'groups multiple ids for the same file together' do
        cmd = repro_command_from(%w[ ./spec/unit/1_spec.rb[1:1] ./spec/unit/1_spec.rb[1:2] ])
        expect(cmd).to include("./spec/unit/1_spec.rb[1:1,1:2]")
      end

      it 'prints the files in alphabetical order' do
        cmd = repro_command_from(%w[ ./spec/unit/2_spec.rb[1:1] ./spec/unit/1_spec.rb[1:1] ])
        expect(cmd).to include("./spec/unit/1_spec.rb[1:1] ./spec/unit/2_spec.rb[1:1]")
      end

      it 'prints ids from the same file in sequential order' do
        cmd = repro_command_from(%w[
          ./spec/unit/1_spec.rb[2:1]
          ./spec/unit/1_spec.rb[1:2]
          ./spec/unit/1_spec.rb[1:1]
          ./spec/unit/1_spec.rb[1:10]
          ./spec/unit/1_spec.rb[1:9]
        ])

        expect(cmd).to include("./spec/unit/1_spec.rb[1:1,1:2,1:9,1:10,2:1]")
      end

      it 'does not include `--bisect` even though the original args do' do
        original_cli_args << "--bisect"
        expect(repro_command_from(%w[ ./foo.rb[1:1] ])).to exclude("bisect")
      end

      it 'quotes the ids on a shell like ZSH that requires it' do
        with_env_vars 'SHELL' => '/usr/local/bin/zsh' do
          expect(repro_command_from(%w[ ./foo.rb[1:1] ])).to include("'./foo.rb[1:1]'")
        end
      end
    end

    describe "#original_locations" do
      let(:original_cli_args) { %w[ spec/unit spec/integration/foo_spec.rb --order defined ] }

      it "returns the original files or directories to run" do
        expect(shell_command.original_locations).to eq %w[spec/unit spec/integration/foo_spec.rb]
      end
    end

    describe "#bisect_environment_hash" do
      let(:original_cli_args) { %w[] }

      context 'when `SPEC_OPTS` has been set' do
        it 'returns a hash with `SPEC_OPTS` set to the opts without --bisect' do
          with_env_vars 'SPEC_OPTS' => '--order defined --bisect' do
            expect(shell_command.bisect_environment_hash).to eq('SPEC_OPTS' => '--order defined')
          end
        end
      end

      context 'when `SPEC_OPTS` has not been set' do
        it 'returns a blank hash' do
          expect(shell_command.bisect_environment_hash).to eq({})
        end
      end
    end

    describe "#spec_opts_without_bisect" do
      let(:original_cli_args) { %w[ ] }

      context 'when `SPEC_OPTS` has been set' do
        it 'returns the spec opts without --bisect' do
          with_env_vars 'SPEC_OPTS' => '--order defined --bisect' do
            expect(shell_command.spec_opts_without_bisect).to eq('--order defined')
          end
        end
      end

      context 'when `SPEC_OPTS` has not been set' do
        it 'returns a blank string' do
          expect(shell_command.spec_opts_without_bisect).to eq('')
        end
      end
    end

    def uses_quoting_for_escaping?
      RSpec::Support::OS.windows? || RSpec::Support::Ruby.jruby?
    end
  end
end
