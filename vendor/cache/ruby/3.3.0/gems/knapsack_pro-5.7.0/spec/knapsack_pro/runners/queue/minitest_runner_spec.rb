describe KnapsackPro::Runners::Queue::MinitestRunner do
  describe '.run' do
    let(:test_suite_token_minitest) { 'fake-token' }
    let(:queue_id) { 'fake-queue-id' }
    let(:test_dir) { 'fake-test-dir' }
    let(:runner) do
      instance_double(described_class, test_dir: test_dir)
    end

    subject { described_class.run(args) }

    before do
      expect(described_class).to receive(:require).with('minitest')

      expect(KnapsackPro::Config::Env).to receive(:test_suite_token_minitest).and_return(test_suite_token_minitest)
      expect(KnapsackPro::Config::EnvGenerator).to receive(:set_queue_id).and_return(queue_id)

      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_TEST_SUITE_TOKEN', test_suite_token_minitest)
      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_QUEUE_RECORDING_ENABLED', 'true')
      expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_QUEUE_ID', queue_id)

      expect(KnapsackPro::Config::Env).to receive(:set_test_runner_adapter).with(KnapsackPro::Adapters::MinitestAdapter)

      expect(described_class).to receive(:new).with(KnapsackPro::Adapters::MinitestAdapter).and_return(runner)

      expect($LOAD_PATH).to receive(:unshift).with(test_dir)
    end

    context 'when args provided' do
      let(:args) { '--verbose --pride' }

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
          args: ['--verbose', '--pride'],
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
          args: [],
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
    let(:runner) { instance_double(described_class) }
    let(:can_initialize_queue) { double(:can_initialize_queue) }
    let(:args) { ['--verbose', '--pride'] }
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
      let(:test_file_paths) { ['a_test.rb', 'b_test.rb', 'fake_path_test.rb'] }

      before do
        subset_queue_id = 'fake-subset-queue-id'
        expect(KnapsackPro::Config::EnvGenerator).to receive(:set_subset_queue_id).and_return(subset_queue_id)

        expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_SUBSET_QUEUE_ID', subset_queue_id)

        tracker = instance_double(KnapsackPro::Tracker)
        expect(KnapsackPro).to receive(:tracker).twice.and_return(tracker)
        expect(tracker).to receive(:reset!)
        expect(tracker).to receive(:set_prerun_tests).with(test_file_paths)

        # .minitest_run
        allow(File).to receive(:exist?)
        expect(File).to receive(:exist?).with('./a_test.rb').and_return(true)
        expect(File).to receive(:exist?).with('./b_test.rb').and_return(true)
        expect(File).to receive(:exist?).with('./fake_path_test.rb').and_return(false)
        expect(described_class).to receive(:require).with('./a_test.rb')
        expect(described_class).to receive(:require).with('./b_test.rb')
        expect(described_class).to_not receive(:require).with('./fake_path_test.rb')

        expect(Minitest).to receive(:run).with(args).and_return(is_tests_green)

        expect(Minitest::Runnable).to receive(:reset)

        expect(KnapsackPro::Hooks::Queue).to receive(:call_before_subset_queue)

        expect(KnapsackPro::Hooks::Queue).to receive(:call_after_subset_queue)

        expect(KnapsackPro::Report).to receive(:save_subset_queue_to_file)
      end

      context 'when tests are passing' do
        let(:is_tests_green) { true }

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
        let(:is_tests_green) { false }

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

    context "when test files don't exist" do
      let(:test_file_paths) { [] }

      context 'when all_test_file_paths exist' do
        let(:all_test_file_paths) { ['a_test.rb'] }

        it 'returns exit code 0' do
          expect(KnapsackPro::Adapters::MinitestAdapter).to receive(:verify_bind_method_called)

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
