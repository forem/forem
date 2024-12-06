describe KnapsackPro::Adapters::SpinachAdapter do
  it do
    expect(described_class::TEST_DIR_PATTERN).to eq 'features/**{,/*/**}/*.feature'
  end

  context do
    it_behaves_like 'adapter'
  end

  describe '.test_path' do
    let(:scenario_data) do
      double(feature: double(filename: 'a.feature'))
    end

    subject { described_class.test_path(scenario_data) }

    it { should eql 'a.feature' }
  end

  describe 'bind methods' do
    describe '#bind_time_tracker' do
      let(:block) { double }
      let(:tracker) { instance_double(KnapsackPro::Tracker) }
      let(:logger) { instance_double(Logger) }
      let(:global_time) { 'Global time: 01m 05s' }
      let(:test_path) { 'features/a.feature' }
      let(:scenario_data) do
        double(feature: double(filename: test_path))
      end

      it do
        expect(Spinach.hooks).to receive(:before_scenario).and_yield(scenario_data, nil)

        allow(KnapsackPro).to receive(:tracker).and_return(tracker)
        expect(described_class).to receive(:test_path).with(scenario_data).and_return(test_path)
        expect(tracker).to receive(:current_test_path=).with(test_path)
        expect(tracker).to receive(:start_timer)

        expect(Spinach.hooks).to receive(:after_scenario).and_yield
        expect(tracker).to receive(:stop_timer)

        expect(Spinach.hooks).to receive(:after_run).and_yield
        expect(KnapsackPro::Presenter).to receive(:global_time).and_return(global_time)
        expect(KnapsackPro).to receive(:logger).and_return(logger)
        expect(logger).to receive(:debug).with(global_time)

        subject.bind_time_tracker
      end
    end

    describe '#bind_save_report' do
      it do
        expect(Spinach.hooks).to receive(:after_run).and_yield

        expect(KnapsackPro::Report).to receive(:save)

        subject.bind_save_report
      end
    end
  end
end
