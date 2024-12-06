describe KnapsackPro::Runners::TestUnitRunner do
  subject { described_class.new(KnapsackPro::Adapters::TestUnitAdapter) }

  it { should be_kind_of KnapsackPro::Runners::BaseRunner }

  describe '.run' do
    let(:args) { '--verbose --order=random' }

    subject { described_class.run(args) }

    before do
      stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN_TEST_UNIT' => 'test-unit-token' })
    end

    context 'when test files were returned by Knapsack Pro API' do
      let(:test_file_paths) { ['test-unit_fake/a_test.rb', 'test-unit_fake/b_test.rb'] }

      it 'runs tests' do
        expect(KnapsackPro::Adapters::TestUnitAdapter).to receive(:verify_bind_method_called)

        tracker = instance_double(KnapsackPro::Tracker)
        expect(KnapsackPro).to receive(:tracker).and_return(tracker)
        expect(tracker).to receive(:set_prerun_tests).with(test_file_paths)

        runner = instance_double(described_class,
                                 test_dir: 'test-unit_fake',
                                 test_file_paths: test_file_paths,
                                 test_files_to_execute_exist?: true)
        expect(described_class).to receive(:new)
        .with(KnapsackPro::Adapters::TestUnitAdapter).and_return(runner)

        auto_runner_exit_code = 0
        expect(described_class).to receive(:test_unit_autorunner_run) do |flag, test_dir, cli_args|
          expect(flag).to be true
          expect(test_dir).to eq 'test-unit_fake'
          expect(cli_args.size).to eq 4
          expect(cli_args[0]).to eq '--verbose'
          expect(cli_args[1]).to eq '--order=random'
          expect(cli_args[2]).to end_with 'test-unit_fake/a_test.rb'
          expect(cli_args[3]).to end_with 'test-unit_fake/b_test.rb'
        end.and_return(auto_runner_exit_code)
        expect(described_class).to receive(:exit).with(auto_runner_exit_code)

        subject

        expect(ENV['KNAPSACK_PRO_TEST_SUITE_TOKEN']).to eq 'test-unit-token'
        expect(ENV['KNAPSACK_PRO_RECORDING_ENABLED']).to eq 'true'
      end
    end

    context 'when test files were not returned by Knapsack Pro API' do
      it "doesn't run tests" do
        runner = instance_double(described_class,
                                 test_files_to_execute_exist?: false)
        expect(described_class).to receive(:new)
        .with(KnapsackPro::Adapters::TestUnitAdapter).and_return(runner)

        subject
      end
    end
  end
end
