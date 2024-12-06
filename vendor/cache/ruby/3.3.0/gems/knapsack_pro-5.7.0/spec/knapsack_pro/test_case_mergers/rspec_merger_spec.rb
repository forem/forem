describe KnapsackPro::TestCaseMergers::RSpecMerger do
  describe '#call' do
    subject { described_class.new(test_files).call }

    context 'when all test files are not test example paths' do
      let(:test_files) do
        [
          { 'path' => 'spec/a_spec.rb', 'time_execution' => 1.1 },
          { 'path' => 'spec/b_spec.rb', 'time_execution' => 2.2 },
        ]
      end

      it do
        expect(subject).to eq([
          { 'path' => 'spec/a_spec.rb', 'time_execution' => 1.1 },
          { 'path' => 'spec/b_spec.rb', 'time_execution' => 2.2 },
        ])
      end
    end

    context 'when test files have test example paths' do
      let(:test_files) do
        [
          { 'path' => 'spec/a_spec.rb', 'time_execution' => 1.1 },
          # test example paths
          { 'path' => 'spec/test_case_spec.rb[1:1]', 'time_execution' => 2.2 },
          { 'path' => 'spec/test_case_spec.rb[1:2]', 'time_execution' => 0.8 },
        ]
      end

      it 'returns merged paths for test examples and sum of their time_execution' do
        expect(subject).to eq([
          { 'path' => 'spec/a_spec.rb', 'time_execution' => 1.1 },
          { 'path' => 'spec/test_case_spec.rb', 'time_execution' => 3.0 },
        ])
      end
    end

    context 'when test files have test example paths and at the same time test file path for test example path is present as full test file path' do
      let(:test_files) do
        [
          { 'path' => 'spec/a_spec.rb', 'time_execution' => 1.1 },
          # full test file path is present despite existing test example paths
          { 'path' => 'spec/test_case_spec.rb', 'time_execution' => 1.0 },
          # test example paths
          { 'path' => 'spec/test_case_spec.rb[1:1]', 'time_execution' => 2.2 },
          { 'path' => 'spec/test_case_spec.rb[1:2]', 'time_execution' => 0.8 },
        ]
      end

      it 'returns merged paths for test examples and sum of their time_execution' do
        expect(subject).to eq([
          { 'path' => 'spec/a_spec.rb', 'time_execution' => 1.1 },
          { 'path' => 'spec/test_case_spec.rb', 'time_execution' => 4.0 },
        ])
      end
    end
  end
end
