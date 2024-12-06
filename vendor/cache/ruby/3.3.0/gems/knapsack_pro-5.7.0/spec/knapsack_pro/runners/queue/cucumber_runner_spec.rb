describe KnapsackPro::Runners::Queue::CucumberRunner do
  describe '.run' do
    let(:test_suite_token_cucumber) { 'fake-token' }
    let(:queue_id) { 'fake-queue-id' }
    let(:test_dir) { 'fake-features-dir' }
    let(:runner) do
      instance_double(described_class, test_dir: test_dir)
    end

    subject { described_class.run(args) }

    before do
      expect(described_class).to receive(:require).with('cucumber/rake/task')

      expect(KnapsackPro::Config::Env).to receive(:test_suite_token_cucumber).and_return(test_suite_token_cucumber)
      expect(KnapsackPro::Config::EnvGenerator).to receive(:set_queue_id).and_return(queue_id)

      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_TEST_SUITE_TOKEN', test_suite_token_cucumber)
      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_QUEUE_RECORDING_ENABLED', 'true')
      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_QUEUE_ID', queue_id)

      expect(KnapsackPro::Config::Env).to receive(:set_test_runner_adapter).with(KnapsackPro::Adapters::CucumberAdapter)

      expect(described_class).to receive(:new).with(KnapsackPro::Adapters::CucumberAdapter).and_return(runner)
    end

    context 'when args provided' do
      let(:args) { '--retry 5 --no-strict-flaky' }

      it do
        expected_exitstatus = 0
        expected_accumulator = {
          status: :completed,
          exitstatus: expected_exitstatus
        }
        accumulator = {
          status: :next,
          runner: runner,
          can_initialize_queue: true,
          args: args,
          exitstatus: 0,
          all_test_file_paths: [],
        }
        expect(described_class).to receive(:handle_signal!)
        expect(described_class).to receive(:run_tests).with(accumulator).and_return(expected_accumulator)

        expect(Kernel).to receive(:exit).with(expected_exitstatus)

        subject
      end
    end

    context 'when args not provided' do
      let(:args) { nil }

      it do
        expected_exitstatus = 0
        expected_accumulator = {
          status: :completed,
          exitstatus: expected_exitstatus
        }
        accumulator = {
          status: :next,
          runner: runner,
          can_initialize_queue: true,
          args: nil,
          exitstatus: 0,
          all_test_file_paths: [],
        }
        expect(described_class).to receive(:handle_signal!)
        expect(described_class).to receive(:run_tests).with(accumulator).and_return(expected_accumulator)

        expect(Kernel).to receive(:exit).with(expected_exitstatus)

        subject
      end
    end
  end

  describe '.run_tests' do
    let(:test_dir) { 'fake-features-dir' }
    let(:runner) do
      instance_double(described_class, test_dir: test_dir)
    end
    let(:can_initialize_queue) { double(:can_initialize_queue) }
    let(:args) { '--retry 5 --no-strict-flaky' }
    let(:exitstatus) { 0 }
    let(:all_test_file_paths) { [] }
    let(:accumulator) do
      {
        runner: runner,
        can_initialize_queue: can_initialize_queue,
        args: args,
        exitstatus: exitstatus,
        all_test_file_paths: all_test_file_paths,
      }
    end

    subject { described_class.run_tests(accumulator) }

    before do
      expect(runner).to receive(:test_file_paths).with(can_initialize_queue: can_initialize_queue, executed_test_files: all_test_file_paths).and_return(test_file_paths)
    end

    context 'when test files exist' do
      let(:test_file_paths) { ['features/a.feature', 'features/b.feature'] }
      let(:child_status) { double }

      before do
        subset_queue_id = 'fake-subset-queue-id'
        expect(KnapsackPro::Config::EnvGenerator).to receive(:set_subset_queue_id).and_return(subset_queue_id)

        expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_SUBSET_QUEUE_ID', subset_queue_id)

        tracker = instance_double(KnapsackPro::Tracker)
        expect(KnapsackPro).to receive(:tracker).twice.and_return(tracker)
        expect(tracker).to receive(:reset!)
        expect(tracker).to receive(:set_prerun_tests).with(test_file_paths)

        expect(KnapsackPro::Hooks::Queue).to receive(:call_before_subset_queue)

        # .cucumber_run
        expect(Kernel).to receive(:system).with('bundle exec cucumber --retry 5 --no-strict-flaky --require fake-features-dir -- "features/a.feature" "features/b.feature"')

        expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_BEFORE_QUEUE_HOOK_CALLED', 'true')

        allow(described_class).to receive(:child_status).and_return(child_status)
        expect(child_status).to receive(:exited?).and_return(process_exited)
        allow(child_status).to receive(:exitstatus).and_return(exitstatus)
      end

      context 'when system process finished its work (exited)' do
        let(:process_exited) { true }

        context 'when tests are passing' do
          let(:exitstatus) { 0 }

          it 'returns exit code 0' do
            expect(subject).to eq({
              status: :next,
              runner: runner,
              can_initialize_queue: false,
              args: args,
              exitstatus: exitstatus,
              all_test_file_paths: test_file_paths,
            })
          end
        end

        context 'when tests are failing' do
          let(:exitstatus) { 1 }

          it 'returns exit code 1' do
            expect(subject).to eq({
              status: :next,
              runner: runner,
              can_initialize_queue: false,
              args: args,
              exitstatus: 1, # tests failed
              all_test_file_paths: test_file_paths,
            })
          end
        end
      end

      context "when system process didn't finish its work (hasn't exited)" do
        let(:process_exited) { false }

        it 'raises an error' do
          expect { subject }.to raise_error(RuntimeError, /^Cucumber process execution failed/)
        end
      end
    end

    context "when test files don't exist" do
      let(:test_file_paths) { [] }

      context 'when all_test_file_paths exist' do
        let(:all_test_file_paths) { ['features/a.feature'] }

        it 'returns exit code 0' do
          expect(KnapsackPro::Adapters::CucumberAdapter).to receive(:verify_bind_method_called)

          expect(KnapsackPro::Hooks::Queue).to receive(:call_after_queue)
          expect(KnapsackPro::Report).to receive(:save_node_queue_to_api)

          expect(subject).to eq({
            status: :completed,
            exitstatus: exitstatus,
          })
        end
      end

      context "when all_test_file_paths don't exist" do
        let(:all_test_file_paths) { [] }

        it 'returns exit code 0' do
          expect(KnapsackPro::Hooks::Queue).to receive(:call_after_queue)
          expect(KnapsackPro::Report).to receive(:save_node_queue_to_api)

          expect(subject).to eq({
            status: :completed,
            exitstatus: exitstatus,
          })
        end
      end
    end
  end
end
