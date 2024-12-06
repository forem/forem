describe KnapsackPro::Runners::MinitestRunner do
  subject { described_class.new(KnapsackPro::Adapters::MinitestAdapter) }

  it { should be_kind_of KnapsackPro::Runners::BaseRunner }

  describe '.run' do
    let(:args) { '--custom-arg' }
    let(:task_name) { 'knapsack_pro:minitest_run' }

    subject { described_class.run(args) }

    before do
      stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN_MINITEST' => 'minitest-token' })
    end

    context 'when test files were returned by Knapsack Pro API' do
      let(:test_file_paths) { ['test_fake/a_test.rb', 'test_fake/b_test.rb'] }

      before do
        expect(KnapsackPro::Adapters::MinitestAdapter).to receive(:verify_bind_method_called)

        tracker = instance_double(KnapsackPro::Tracker)
        expect(KnapsackPro).to receive(:tracker).and_return(tracker)
        expect(tracker).to receive(:set_prerun_tests).with(test_file_paths)
      end

      it 'runs tests' do
        runner = instance_double(described_class,
                                 test_dir: 'test',
                                 test_file_paths: test_file_paths,
                                 test_files_to_execute_exist?: true)
        expect(described_class).to receive(:new)
        .with(KnapsackPro::Adapters::MinitestAdapter).and_return(runner)

        expect(Rake::Task.task_defined?(task_name)).to be false

        subject

        expect(Rake::Task.task_defined?(task_name)).to be true

        expect(ENV['KNAPSACK_PRO_TEST_SUITE_TOKEN']).to eq 'minitest-token'
        expect(ENV['KNAPSACK_PRO_RECORDING_ENABLED']).to eq 'true'
      end
    end

    context 'when test files were not returned by Knapsack Pro API' do
      it "doesn't run tests" do
        runner = instance_double(described_class,
                                 test_files_to_execute_exist?: false)
        expect(described_class).to receive(:new)
        .with(KnapsackPro::Adapters::MinitestAdapter).and_return(runner)

        subject
      end
    end
  end
end
