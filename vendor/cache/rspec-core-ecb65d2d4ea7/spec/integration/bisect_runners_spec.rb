require 'support/aruba_support'
require 'rspec/core/bisect/shell_command'
require 'rspec/core/bisect/shell_runner'
require 'rspec/core/bisect/fork_runner'

module RSpec::Core
  RSpec.shared_examples_for "a bisect runner" do
    include_context "aruba support"
    before { setup_aruba }

    let(:shell_command) { Bisect::ShellCommand.new([]) }

    def with_runner(&block)
      handle_current_dir_change do
        cd '.' do
          options = ConfigurationOptions.new(shell_command.original_cli_args)
          runner = Runner.new(options)
          output = StringIO.new
          runner.configure(output, output)
          described_class.start(shell_command, runner, &block)
        end
      end
    end

    it 'runs the specs in an isolated environment and reports the results' do
      RSpec.configuration.formatter = 'progress'

      write_file 'spec/a_spec.rb', "
        formatters = RSpec.configuration.formatter_loader.formatters
        if formatters.any? { |f| f.is_a?(RSpec::Core::Formatters::ProgressFormatter) }
          raise 'Leaked progress formatter from host environment'
        end

        RSpec.describe 'A group' do
          it('passes') { expect(1).to eq 1 }
          it('fails')  { expect(1).to eq 2 }
        end
      "

      with_runner do |runner|
        expect(runner.original_results).to have_attributes(
          :all_example_ids => %w[ ./spec/a_spec.rb[1:1] ./spec/a_spec.rb[1:2] ],
          :failed_example_ids => %w[ ./spec/a_spec.rb[1:2] ]
        )

        expect(runner.run(%w[ ./spec/a_spec.rb[1:1] ])).to have_attributes(
          :all_example_ids => %w[ ./spec/a_spec.rb[1:1] ],
          :failed_example_ids => %w[]
        )
      end
    end

    it 'honors `run_all_when_everything_filtered`' do
      write_file 'spec/a_spec.rb', "
        RSpec.configure do |c|
          c.filter_run :focus
          c.run_all_when_everything_filtered = true
        end

        RSpec.describe 'A group' do
          it('passes') { expect(1).to eq 1 }
          it('fails')  { expect(1).to eq 2 }
        end
      "

      with_runner do |runner|
        expect(runner.original_results).to have_attributes(
          :all_example_ids => %w[ ./spec/a_spec.rb[1:1] ./spec/a_spec.rb[1:2] ],
          :failed_example_ids => %w[ ./spec/a_spec.rb[1:2] ]
        )
      end
    end

    it 'raises BisectFailedError with all run output when it encounters an error loading spec files' do
      write_file 'spec/a_spec.rb', "
        puts 'stdout in a_spec'
        warn 'stderr in a_spec'

        RSpec.escribe 'A group' do
          it('passes') { expect(1).to eq 1 }
          it('fails')  { expect(1).to eq 2 }
        end
      "

      with_runner do |runner|
        expect {
          runner.original_results
        }.to raise_error(Bisect::BisectFailedError, a_string_including(
          "undefined method `escribe' for RSpec:Module",
          'stdout in a_spec',
          'stderr in a_spec'
        ))
      end
    end
  end

  RSpec.describe Bisect::ShellRunner, :slow do
    include_examples 'a bisect runner'
  end

  RSpec.describe Bisect::ForkRunner, :if => RSpec::Support::RubyFeatures.fork_supported? do
    include_examples 'a bisect runner'

    context 'when a `--require` option has been provided' do
      let(:shell_command) { Bisect::ShellCommand.new(['--require', './spec/a_spec_helper']) }

      it 'loads the specified file only once (rather than once per subset run)' do
        write_file 'spec_helper_loads', ''
        write_file 'spec/a_spec_helper.rb', "
          File.open('spec_helper_loads', 'a') do |f|
            f.print('.')
          end
        "

        write_file 'spec/a_spec.rb', "
          RSpec.describe 'A group' do
            it('passes') { expect(1).to eq 1 }
            it('fails')  { expect(1).to eq 2 }
          end
        "

        with_runner do |runner|
          runner.run(%w[ ./spec/a_spec.rb[1:1] ])
          runner.run(%w[ ./spec/a_spec.rb[1:1] ])
        end

        cd '.' do
          expect(File.read('spec_helper_loads')).to eq(".")
        end
      end
    end
  end
end
