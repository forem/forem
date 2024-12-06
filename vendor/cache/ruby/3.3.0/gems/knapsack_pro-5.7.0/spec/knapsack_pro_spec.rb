describe KnapsackPro do
  describe '.root' do
    subject { described_class.root }

    it { expect(subject).to match 'knapsack_pro-ruby' }
  end

  describe '.logger' do
    let(:logger_wrapper) { double }

    subject { described_class.logger }

    before { described_class.reset_logger! }
    after { described_class.reset_logger! }

    context 'when KNAPSACK_PRO_LOG_DIR is set' do
      let(:logger) { instance_double(Logger) }

      context 'when KNAPSACK_PRO_CI_NODE_INDEX is set' do
        before do
          stub_const('ENV', {
            'KNAPSACK_PRO_LOG_DIR' => 'log',
            'KNAPSACK_PRO_CI_NODE_INDEX' => 1,
          })

          expect(Logger).to receive(:new).with('log/knapsack_pro_node_1.log').and_return(logger)
          expect(logger).to receive(:level=).with(Logger::DEBUG)
          expect(KnapsackPro::LoggerWrapper).to receive(:new).with(logger).and_return(logger_wrapper)
        end

        it { should eql logger_wrapper }
      end

      context 'when KNAPSACK_PRO_CI_NODE_INDEX is not set' do
        before do
          stub_const('ENV', {
            'KNAPSACK_PRO_LOG_DIR' => 'log',
          })

          expect(Logger).to receive(:new).with('log/knapsack_pro_node_0.log').and_return(logger)
          expect(logger).to receive(:level=).with(Logger::DEBUG)
          expect(KnapsackPro::LoggerWrapper).to receive(:new).with(logger).and_return(logger_wrapper)
        end

        it { should eql logger_wrapper }
      end
    end

    context 'when default logger' do
      let(:logger) { instance_double(Logger) }

      before do
        expect(Logger).to receive(:new).with(STDOUT).and_return(logger)
        expect(logger).to receive(:level=).with(Logger::DEBUG)
        expect(KnapsackPro::LoggerWrapper).to receive(:new).with(logger).and_return(logger_wrapper)
      end

      it { should eql logger_wrapper }
    end

    context 'when custom logger' do
      let(:logger) { double('custom logger') }

      before do
        expect(KnapsackPro::LoggerWrapper).to receive(:new).with(logger).and_return(logger_wrapper)
        described_class.logger = logger
      end

      it { should eql logger_wrapper }
    end
  end

  describe '.tracker' do
    subject { described_class.tracker }

    it { should be_a KnapsackPro::Tracker }
    it { expect(subject.object_id).to eql described_class.tracker.object_id }
  end

  describe '.load_tasks' do
    let(:task_loader) { instance_double(KnapsackPro::TaskLoader) }

    it do
      expect(KnapsackPro::TaskLoader).to receive(:new).and_return(task_loader)
      expect(task_loader).to receive(:load_tasks)
      described_class.load_tasks
    end
  end
end
