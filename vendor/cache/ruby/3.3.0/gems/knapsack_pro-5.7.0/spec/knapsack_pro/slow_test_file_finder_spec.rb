describe KnapsackPro::SlowTestFileFinder do
  describe '.call' do
    let(:adapter_class) { double }

    subject { described_class.call(adapter_class) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:test_files_encrypted?).and_return(test_files_encrypted?)
    end

    context 'when test files are not encrypted' do
      let(:test_files_encrypted?) { false }

      it do
        test_files_from_api = double
        time_execution = double
        build_distribution_entity = instance_double(KnapsackPro::BuildDistributionFetcher::BuildDistributionEntity, test_files: test_files_from_api, time_execution: time_execution)
        expect(KnapsackPro::BuildDistributionFetcher).to receive(:call).and_return(build_distribution_entity)

        merged_test_files_from_api = double
        expect(KnapsackPro::TestCaseMergers::BaseMerger).to receive(:call).with(adapter_class, test_files_from_api).and_return(merged_test_files_from_api)

        test_files_existing_on_disk = double
        expect(KnapsackPro::TestFileFinder).to receive(:select_test_files_that_can_be_run).with(adapter_class, merged_test_files_from_api).and_return(test_files_existing_on_disk)

        slow_test_files = double
        expect(KnapsackPro::SlowTestFileDeterminer).to receive(:call).with(test_files_existing_on_disk, time_execution).and_return(slow_test_files)

        expect(KnapsackPro::SlowTestFileDeterminer).to receive(:save_to_json_report).with(slow_test_files)

        expect(subject).to eq slow_test_files
      end
    end

    context 'when test files are encrypted' do
      let(:test_files_encrypted?) { true }

      it do
        expect { subject }.to raise_error RuntimeError, 'Split by test cases is not possible when you have enabled test file names encryption ( https://knapsackpro.com/perma/ruby/encryption ). You need to disable encryption with KNAPSACK_PRO_TEST_FILES_ENCRYPTED=false in order to use split by test cases https://knapsackpro.com/perma/ruby/split-by-test-examples'
      end
    end
  end
end
