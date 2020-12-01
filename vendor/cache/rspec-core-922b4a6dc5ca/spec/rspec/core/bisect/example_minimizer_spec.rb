require 'rspec/core/bisect/example_minimizer'
require 'rspec/core/bisect/server'
require 'rspec/core/bisect/shell_command'
require 'support/fake_bisect_runner'

module RSpec::Core
  RSpec.describe Bisect::ExampleMinimizer do
    around do |ex|
      # so example ids do not have to be escaped
      with_env_vars('SHELL' => 'bash', &ex)
    end

    let(:fake_runner) do
      FakeBisectRunner.new(
        %w[ 1.rb[1] 2.rb[1] 3.rb[1] 4.rb[1] 5.rb[1] 6.rb[1] 7.rb[1] 8.rb[1] ],
        %w[ 2.rb[1] ],
        { "5.rb[1]" => %w[ 4.rb[1] ] }
      )
    end

    it 'repeatedly runs various subsets of the suite, removing examples that have no effect on the failing examples' do
      minimizer = new_minimizer(fake_runner)
      minimizer.find_minimal_repro
      expect(minimizer.repro_command_for_currently_needed_ids).to eq("rspec 2.rb[1] 4.rb[1] 5.rb[1]")
    end

    it 'reduces a failure where none of the passing examples are implicated' do
      no_dependents_runner = FakeBisectRunner.new(
        %w[ 1.rb[1] 2.rb[1] ],
        %w[ 2.rb[1] ],
        {}
      )
      minimizer = new_minimizer(no_dependents_runner)
      minimizer.find_minimal_repro
      expect(minimizer.repro_command_for_currently_needed_ids).to eq("rspec 2.rb[1]")
    end

    it 'reduces a failure when more than 50% of examples are implicated' do
      fake_runner.always_failures = []
      fake_runner.dependent_failures = { "8.rb[1]" => %w[ 1.rb[1] 2.rb[1] 3.rb[1] 4.rb[1] 5.rb[1] 6.rb[1] ] }
      minimizer = new_minimizer(fake_runner)
      minimizer.find_minimal_repro
      expect(minimizer.repro_command_for_currently_needed_ids).to eq(
        "rspec 1.rb[1] 2.rb[1] 3.rb[1] 4.rb[1] 5.rb[1] 6.rb[1] 8.rb[1]"
      )
    end

    it 'reduces a failure with multiple dependencies' do
      fake_runner.always_failures = []
      fake_runner.dependent_failures = { "8.rb[1]" => %w[ 1.rb[1] 3.rb[1] 5.rb[1] 7.rb[1] ] }
      minimizer = new_minimizer(fake_runner)
      minimizer.find_minimal_repro
      expect(minimizer.repro_command_for_currently_needed_ids).to eq(
        "rspec 1.rb[1] 3.rb[1] 5.rb[1] 7.rb[1] 8.rb[1]"
      )
    end

    context 'with an unminimisable failure' do
      class RunCountingReporter < RSpec::Core::NullReporter
        attr_accessor :round_count
        attr_accessor :example_count
        def initialize
          @round_count = 0
        end

        def publish(event, *args)
          send(event, *args) if respond_to? event
        end

        def bisect_individual_run_start(_notification)
          self.round_count += 1
        end
      end

      let(:counting_reporter) { RunCountingReporter.new }
      let(:fake_runner) do
        FakeBisectRunner.new(
          %w[ 1.rb[1] 2.rb[1] 3.rb[1] 4.rb[1] 5.rb[1] 6.rb[1] 7.rb[1] 8.rb[1] 9.rb[1] ],
          [],
          "9.rb[1]" => %w[ 1.rb[1] 2.rb[1] 3.rb[1] 4.rb[1] 5.rb[1] 6.rb[1] 7.rb[1] 8.rb[1] ]
        )
      end
      let(:counting_minimizer) do
        new_minimizer(fake_runner, counting_reporter)
      end

      it 'returns the full command if the failure can not be reduced' do
        counting_minimizer.find_minimal_repro

        expect(counting_minimizer.repro_command_for_currently_needed_ids).to eq(
          "rspec 1.rb[1] 2.rb[1] 3.rb[1] 4.rb[1] 5.rb[1] 6.rb[1] 7.rb[1] 8.rb[1] 9.rb[1]"
        )
      end

      it 'detects an unminimisable failure in the minimum number of runs' do
        counting_minimizer.find_minimal_repro

        # The recursive bisection strategy should take 1 + 2 + 4 + 8 = 15 runs
        # to determine that a failure is fully dependent on 8 preceding
        # examples:
        #
        # 1 run to determine that any of the candidates are culprits
        # 2 runs to determine that each half contains a culprit
        # 4 runs to determine that each quarter contains a culprit
        # 8 runs to determine that each candidate is a culprit
        expect(counting_reporter.round_count).to eq(15)
      end
    end

    it 'ignores flapping examples that did not fail on the initial full run but fail on later runs' do
      def fake_runner.run(ids)
        super.tap do |results|
          @run_count ||= 0
          if (@run_count += 1) > 1
            results.failed_example_ids << "8.rb[1]"
          end
        end
      end

      minimizer = new_minimizer(fake_runner)
      minimizer.find_minimal_repro
      expect(minimizer.repro_command_for_currently_needed_ids).to eq("rspec 2.rb[1] 4.rb[1] 5.rb[1]")
    end

    it 'aborts early when no examples fail' do
      minimizer = new_minimizer(FakeBisectRunner.new(
        %w[ 1.rb[1] 2.rb[1] ], [],  {}
      ))

      expect {
        minimizer.find_minimal_repro
      }.to raise_error(RSpec::Core::Bisect::BisectFailedError, /No failures found/i)
    end

    context "when the `repro_command_for_currently_needed_ids` is queried before it has sufficient information" do
      it 'returns an explanation that will be printed when the bisect run is aborted immediately' do
        minimizer = new_minimizer(FakeBisectRunner.new([], [], {}))
        expect(minimizer.repro_command_for_currently_needed_ids).to include("Not yet enough information")
      end
    end

    def new_minimizer(runner, reporter=RSpec::Core::NullReporter)
      shell_command = Bisect::ShellCommand.new([])
      Bisect::ExampleMinimizer.new(shell_command, runner, reporter)
    end
  end
end
