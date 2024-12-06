require 'cucumber/rake/task'

describe KnapsackPro::Runners::CucumberRunner do
  subject { described_class.new(KnapsackPro::Adapters::CucumberAdapter) }

  it { should be_kind_of KnapsackPro::Runners::BaseRunner }

  describe '.run' do
    let(:args) { '--custom-arg' }

    let(:test_suite_token_cucumber) { 'fake-token' }

    subject { described_class.run(args) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:test_suite_token_cucumber).and_return(test_suite_token_cucumber)

      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_TEST_SUITE_TOKEN', test_suite_token_cucumber)
      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_RECORDING_ENABLED', 'true')

      expect(KnapsackPro::Config::Env).to receive(:set_test_runner_adapter).with(KnapsackPro::Adapters::CucumberAdapter)

      expect(described_class).to receive(:new)
      .with(KnapsackPro::Adapters::CucumberAdapter).and_return(runner)
    end

    context 'when test files were returned by Knapsack Pro API' do
      let(:test_dir) { 'fake-test-dir' }
      let(:test_file_paths) { ['features/fake1.scenario', 'features/fake2.scenario'] }
      let(:stringify_test_file_paths) { test_file_paths.join(' ') }
      let(:runner) do
        instance_double(described_class,
                        test_dir: test_dir,
                        test_file_paths: test_file_paths,
                        stringify_test_file_paths: stringify_test_file_paths,
                        test_files_to_execute_exist?: true)
      end
      let(:task) { double }

      before do
        expect(KnapsackPro::Adapters::CucumberAdapter).to receive(:verify_bind_method_called)

        tracker = instance_double(KnapsackPro::Tracker)
        expect(KnapsackPro).to receive(:tracker).and_return(tracker)
        expect(tracker).to receive(:set_prerun_tests).with(test_file_paths)

        expect(Rake::Task).to receive(:[]).with('knapsack_pro:cucumber_run').at_least(1).and_return(task)

        t = double
        expect(Cucumber::Rake::Task).to receive(:new).with('knapsack_pro:cucumber_run').and_yield(t)
        expect(t).to receive(:cucumber_opts=).with('--custom-arg --require fake-test-dir -- features/fake1.scenario features/fake2.scenario')
      end

      context 'when task already exists' do
        before do
          expect(Rake::Task).to receive(:task_defined?).with('knapsack_pro:cucumber_run').and_return(true)
          expect(task).to receive(:clear)
        end

        it do
          result = double(:result)
          expect(task).to receive(:invoke).and_return(result)
          expect(subject).to eq result
        end
      end

      context "when task doesn't exist" do
        before do
          expect(Rake::Task).to receive(:task_defined?).with('knapsack_pro:cucumber_run').and_return(false)
          expect(task).not_to receive(:clear)
        end

        it do
          result = double(:result)
          expect(task).to receive(:invoke).and_return(result)
          expect(subject).to eq result
        end
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
