require 'rspec/core/rake_task'

describe KnapsackPro::Runners::RSpecRunner do
  subject { described_class.new(KnapsackPro::Adapters::RSpecAdapter) }

  it { should be_kind_of KnapsackPro::Runners::BaseRunner }

  describe '.run' do
    let(:args) { '--profile --color' }

    let(:test_suite_token_rspec) { 'fake-token' }

    subject { described_class.run(args) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:test_suite_token_rspec).and_return(test_suite_token_rspec)

      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_TEST_SUITE_TOKEN', test_suite_token_rspec)
      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_RECORDING_ENABLED', 'true')

      expect(KnapsackPro::Config::Env).to receive(:set_test_runner_adapter).with(KnapsackPro::Adapters::RSpecAdapter)

      expect(described_class).to receive(:new)
      .with(KnapsackPro::Adapters::RSpecAdapter).and_return(runner)
    end

    context 'when test files were returned by Knapsack Pro API' do
      let(:test_dir) { 'fake-test-dir' }
      let(:test_file_paths) { ['spec/a_spec.rb', 'spec/b_spec.rb[1:1]'] }
      let(:stringify_test_file_paths) { test_file_paths.join(' ') }
      let(:runner) do
        instance_double(described_class,
                        test_dir: test_dir,
                        test_file_paths: test_file_paths,
                        stringify_test_file_paths: stringify_test_file_paths,
                        test_files_to_execute_exist?: true)
      end
      let(:task) { double }
      let(:task_config) { double }

      before do
        expect(KnapsackPro::Adapters::RSpecAdapter).to receive(:verify_bind_method_called).ordered
        expect(KnapsackPro::Adapters::RSpecAdapter).to receive(:ensure_no_tag_option_when_rspec_split_by_test_examples_enabled!).with(['--profile', '--color']).ordered

        tracker = instance_double(KnapsackPro::Tracker)
        expect(KnapsackPro).to receive(:tracker).and_return(tracker)
        expect(tracker).to receive(:set_prerun_tests).with(test_file_paths)

        expect(Rake::Task).to receive(:[]).with('knapsack_pro:rspec_run').at_least(1).and_return(task)

        expect(RSpec::Core::RakeTask).to receive(:new).with('knapsack_pro:rspec_run').and_yield(task_config)
        expect(task_config).to receive(:rspec_opts=).with('--profile --color --default-path fake-test-dir spec/a_spec.rb spec/b_spec.rb[1:1]')
        expect(task_config).to receive(:pattern=).with([])
      end

      shared_examples 'invokes RSpec rake task' do
        context 'when rake task already exists' do
          before do
            expect(Rake::Task).to receive(:task_defined?).with('knapsack_pro:rspec_run').and_return(true)
            expect(task).to receive(:clear)
          end

          it do
            result = double(:result)
            expect(task).to receive(:invoke).and_return(result)
            expect(subject).to eq result
          end
        end

        context "when rake task doesn't exist" do
          before do
            expect(Rake::Task).to receive(:task_defined?).with('knapsack_pro:rspec_run').and_return(false)
            expect(task).not_to receive(:clear)
          end

          it do
            result = double(:result)
            expect(task).to receive(:invoke).and_return(result)
            expect(subject).to eq result
          end
        end
      end

      context 'when the default log level' do
        before do
          expect(task_config).to receive(:verbose=).with(true)
        end

        it_behaves_like 'invokes RSpec rake task'
      end

      context 'when the warning log level' do
        before do
          expect(KnapsackPro::Config::Env).to receive(:log_level).and_return(::Logger::WARN)

          expect(task_config).to receive(:verbose=).with(false)
        end

        it_behaves_like 'invokes RSpec rake task'
      end
    end

    context 'when test files were not returned by Knapsack Pro API' do
      let(:runner) do
        instance_double(described_class,
                        test_files_to_execute_exist?: false)
      end

      it "doesn't run tests" do
        subject
      end
    end
  end
end
