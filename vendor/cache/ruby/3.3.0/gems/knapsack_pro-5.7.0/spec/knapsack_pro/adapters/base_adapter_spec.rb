describe KnapsackPro::Adapters::BaseAdapter do
  it do
    expect(described_class::TEST_DIR_PATTERN).to eq 'test/**{,/*/**}/*_test.rb'
  end

  shared_examples '.slow_test_file? method' do
    context 'when test_file_path is in slow test file paths' do
      # add ./ before path to ensure KnapsackPro::TestFileCleaner.clean will clean it
      let(:test_file_path) { './spec/models/user_spec.rb' }

      it do
        expect(subject).to be true
      end
    end

    context 'when test_file_path is not in slow test file paths' do
      let(:test_file_path) { './spec/models/article_spec.rb' }

      it do
        expect(subject).to be false
      end
    end
  end

  describe '.adapter_bind_method_called_file' do
    subject { described_class.adapter_bind_method_called_file }

    before do
      expect(KnapsackPro::Config::Env).to receive(:ci_node_index).and_return(ci_node_index)
    end

    context 'when CI node index 0' do
      let(:ci_node_index) { 0 }

      it { expect(subject).to eq '.knapsack_pro/KnapsackPro-Adapters-BaseAdapter-bind_method_called_for_node_0.txt' }
    end

    context 'when CI node index 1' do
      let(:ci_node_index) { 1 }

      it { expect(subject).to eq '.knapsack_pro/KnapsackPro-Adapters-BaseAdapter-bind_method_called_for_node_1.txt' }
    end
  end

  describe '.split_by_test_cases_enabled?' do
    subject { described_class.split_by_test_cases_enabled? }

    it { expect(subject).to be false }
  end

  describe '.test_file_cases_for' do
    subject { described_class.test_file_cases_for([]) }

    it { expect { subject }.to raise_error NotImplementedError }
  end

  describe '.slow_test_file?' do
    let(:adapter_class) { double }
    let(:slow_test_files) do
      [
        { 'path' => 'spec/models/user_spec.rb' },
        { 'path' => 'spec/controllers/users_spec.rb' },
      ]
    end

    subject { described_class.slow_test_file?(adapter_class, test_file_path) }

    before do
      # reset class variable
      described_class.instance_variable_set(:@slow_test_file_paths, nil)
    end

    context 'when slow test file pattern is present' do
      before do
        stub_const('ENV', {
          'KNAPSACK_PRO_SLOW_TEST_FILE_PATTERN' => '{spec/models/*_spec.rb}',
        })
        expect(KnapsackPro::TestFileFinder).to receive(:slow_test_files_by_pattern).with(adapter_class).and_return(slow_test_files)
      end

      it_behaves_like '.slow_test_file? method'
    end

    context 'when slow test file pattern is not present' do
      before do
        expect(KnapsackPro::SlowTestFileDeterminer).to receive(:read_from_json_report).and_return(slow_test_files)
      end

      it_behaves_like '.slow_test_file? method'
    end
  end

  describe '.bind' do
    let(:adapter) { instance_double(described_class) }

    subject { described_class.bind }

    before do
      expect(described_class).to receive(:new).and_return(adapter)
      expect(adapter).to receive(:bind)
    end

    it { should eql adapter }
  end

  describe '.verify_bind_method_called' do
    let(:temp_directory_path) { '.knapsack_pro' }

    subject { described_class.verify_bind_method_called }

    before do
      expect(::Kernel).to receive(:at_exit).and_yield
      allow(File).to receive(:exist?)
      expect(File).to receive(:exist?).with('.knapsack_pro/KnapsackPro-Adapters-BaseAdapter-bind_method_called_for_node_0.txt').and_return(adapter_bind_method_called_file_exists)
    end

    context 'when adapter bind method called' do
      let(:adapter_bind_method_called_file_exists) { true }

      it do
        expect(File).to receive(:delete).with('.knapsack_pro/KnapsackPro-Adapters-BaseAdapter-bind_method_called_for_node_0.txt')
        subject
      end
    end

    context 'when adapter bind method was not call' do
      let(:adapter_bind_method_called_file_exists) { false }

      it do
        expect(Kernel).to receive(:exit).with(1)
        subject
      end
    end
  end

  describe '#bind' do
    let(:temp_directory_path) { '.knapsack_pro' }
    let(:recording_enabled?) { false }
    let(:queue_recording_enabled?) { false }

    before do
      expect(KnapsackPro::Config::TempFiles).to receive(:ensure_temp_directory_exists!)
      expect(File).to receive(:write).with('.knapsack_pro/KnapsackPro-Adapters-BaseAdapter-bind_method_called_for_node_0.txt', nil)

      expect(KnapsackPro::Config::Env).to receive(:recording_enabled?).and_return(recording_enabled?)
      expect(KnapsackPro::Config::Env).to receive(:queue_recording_enabled?).and_return(queue_recording_enabled?)
    end

    after { subject.bind }

    context 'when recording enabled' do
      let(:recording_enabled?) { true }

      before do
        allow(subject).to receive(:bind_time_tracker)
        allow(subject).to receive(:bind_save_report)
      end

      it do
        logger = instance_double(Logger)
        expect(KnapsackPro).to receive(:logger).and_return(logger)
        expect(logger).to receive(:debug).with('Test suite time execution recording enabled.')
      end
      it { expect(subject).to receive(:bind_time_tracker) }
      it { expect(subject).to receive(:bind_save_report) }
    end

    context 'when queue recording enabled' do
      let(:queue_recording_enabled?) { true }

      before do
        allow(subject).to receive(:bind_before_queue_hook)
        allow(subject).to receive(:bind_time_tracker)
      end

      it do
        logger = instance_double(Logger)
        expect(KnapsackPro).to receive(:logger).and_return(logger)
        expect(logger).to receive(:debug).with('Test suite time execution queue recording enabled.')
      end
      it { expect(subject).to receive(:bind_before_queue_hook) }
      it { expect(subject).to receive(:bind_time_tracker) }
    end

    context 'when recording disabled' do
      it { expect(subject).not_to receive(:bind_time_tracker) }
      it { expect(subject).not_to receive(:bind_save_report) }
      it { expect(subject).not_to receive(:bind_before_queue_hook) }
    end
  end

  describe '#bind_time_tracker' do
    it do
      expect {
        subject.bind_time_tracker
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#bind_save_report' do
    it do
      expect {
        subject.bind_save_report
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#bind_before_queue_hook' do
    it do
      expect {
        subject.bind_before_queue_hook
      }.to raise_error(NotImplementedError)
    end
  end
end
