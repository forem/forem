describe KnapsackPro::Adapters::CucumberAdapter do
  it do
    expect(described_class::TEST_DIR_PATTERN).to eq 'features/**{,/*/**}/*.feature'
  end

  context do
    context 'when Cucumber version 1' do
      before do
        stub_const('Cucumber::VERSION', '1.3.20')
        allow(::Cucumber::RbSupport::RbDsl).to receive(:register_rb_hook)
        allow(Kernel).to receive(:at_exit)
      end

      it_behaves_like 'adapter'
    end

    context 'when Cucumber version 2' do
      before do
        stub_const('Cucumber::VERSION', '2')
        allow(::Cucumber::RbSupport::RbDsl).to receive(:register_rb_hook)
        allow(Kernel).to receive(:at_exit)
      end

      it_behaves_like 'adapter'
    end

    context 'when Cucumber version 3' do
      before do
        stub_const('Cucumber::VERSION', '3.0.0')
        allow(::Cucumber::Glue::Dsl).to receive(:register_rb_hook)
        allow(Kernel).to receive(:at_exit)
      end

      it_behaves_like 'adapter'
    end
  end

  describe '.test_path' do
    context 'when Cucumber version 1' do
      subject { described_class.test_path(scenario_or_outline_table) }

      before { stub_const('Cucumber::VERSION', '1') }

      context 'when cucumber >= 1.3' do
        context 'when scenario' do
          let(:scenario_file) { 'features/scenario.feature' }
          let(:scenario_or_outline_table) { double(file: scenario_file) }

          it { should eql scenario_file }
        end

        context 'when scenario outline' do
          let(:scenario_outline_file) { 'features/scenario_outline.feature' }
          let(:scenario_or_outline_table) do
            double(scenario_outline: double(file: scenario_outline_file))
          end

          it { should eql scenario_outline_file }
        end
      end

      context 'when cucumber < 1.3' do
        context 'when scenario' do
          let(:scenario_file) { 'features/scenario.feature' }
          let(:scenario_or_outline_table) { double(feature: double(file: scenario_file)) }

          it { should eql scenario_file }
        end

        context 'when scenario outline' do
          let(:scenario_outline_file) { 'features/scenario_outline.feature' }
          let(:scenario_or_outline_table) do
            double(scenario_outline: double(feature: double(file: scenario_outline_file)))
          end

          it { should eql scenario_outline_file }
        end
      end
    end

    context 'when Cucumber version 2' do
      let(:file) { 'features/a.feature' }
      let(:test_case) { double(location: double(file: file)) } # Cucumber 2

      subject { described_class.test_path(test_case) }

      before { stub_const('Cucumber::VERSION', '2') }

      it { should eql file }
    end
  end

  describe 'bind methods' do
    describe '#bind_time_tracker' do
      let(:file) { 'features/a.feature' }
      let(:block) { double }
      let(:tracker) { instance_double(KnapsackPro::Tracker) }
      let(:logger) { instance_double(Logger) }
      let(:global_time) { 'Global time: 01m 05s' }

      context 'when Cucumber version 1' do
        let(:scenario) { double(file: file) }

        before { stub_const('Cucumber::VERSION', '1.3.20') }

        it do
          expect(subject).to receive(:Around).and_yield(scenario, block)
          allow(KnapsackPro).to receive(:tracker).and_return(tracker)
          expect(tracker).to receive(:current_test_path=).with(file)
          expect(tracker).to receive(:start_timer)
          expect(block).to receive(:call)
          expect(tracker).to receive(:stop_timer)

          expect(::Kernel).to receive(:at_exit).and_yield
          expect(KnapsackPro::Presenter).to receive(:global_time).and_return(global_time)
          expect(KnapsackPro).to receive(:logger).and_return(logger)
          expect(logger).to receive(:debug).with(global_time)

          subject.bind_time_tracker
        end
      end

      context 'when Cucumber version 2' do
        let(:test_case) { double(location: double(file: file)) }

        # complex version name to ensure we can catch that too
        before { stub_const('Cucumber::VERSION', '2.0.0.rc.5') }

        it do
          expect(subject).to receive(:Around).and_yield(test_case, block)
          allow(KnapsackPro).to receive(:tracker).and_return(tracker)
          expect(tracker).to receive(:current_test_path=).with(file)
          expect(tracker).to receive(:start_timer)
          expect(block).to receive(:call)
          expect(tracker).to receive(:stop_timer)

          expect(::Kernel).to receive(:at_exit).and_yield
          expect(KnapsackPro::Presenter).to receive(:global_time).and_return(global_time)
          expect(KnapsackPro).to receive(:logger).and_return(logger)
          expect(logger).to receive(:debug).with(global_time)

          subject.bind_time_tracker
        end
      end
    end

    describe '#bind_save_report' do
      it do
        expect(::Kernel).to receive(:at_exit).and_yield

        expect(KnapsackPro::Report).to receive(:save)

        subject.bind_save_report
      end

      context 'when cucumber tests failed' do
        let(:exit_status) { double }
        let(:latest_error) { instance_double(SystemExit, status: exit_status) }

        it 'preserves cucumber latest error message exit status' do
          expect(::Kernel).to receive(:at_exit).and_yield

          expect(latest_error).to receive(:is_a?).with(SystemExit).and_return(true)
          expect(KnapsackPro::Report).to receive(:save)
          expect(::Kernel).to receive(:exit).with(exit_status)

          subject.bind_save_report(latest_error)
        end
      end
    end

    describe '#bind_before_queue_hook' do
      let(:block) { double }
      let(:scenario) { double(:scenario) }

      context 'when KNAPSACK_PRO_BEFORE_QUEUE_HOOK_CALLED is not set' do
        before { stub_const("ENV", {}) }

        it do
          expect(subject).to receive(:Around).and_yield(scenario, block)

          expect(KnapsackPro::Hooks::Queue).to receive(:call_before_queue)
          expect(ENV).to receive(:[]=).with('KNAPSACK_PRO_BEFORE_QUEUE_HOOK_CALLED', 'true')

          expect(block).to receive(:call)

          subject.bind_before_queue_hook
        end
      end

      context 'when KNAPSACK_PRO_BEFORE_QUEUE_HOOK_CALLED is set' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_BEFORE_QUEUE_HOOK_CALLED' => 'true' }) }

        it do
          expect(subject).to receive(:Around).and_yield(scenario, block)

          expect(KnapsackPro::Hooks::Queue).not_to receive(:call_before_queue)

          expect(block).to receive(:call)

          subject.bind_before_queue_hook
        end
      end
    end

    describe '#bind_queue_mode' do
      it do
        expect(subject).to receive(:bind_before_queue_hook)
        expect(subject).to receive(:bind_time_tracker)

        expect(::Kernel).to receive(:at_exit).and_yield
        expect(KnapsackPro::Hooks::Queue).to receive(:call_after_subset_queue)
        expect(KnapsackPro::Report).to receive(:save_subset_queue_to_file)

        subject.bind_queue_mode
      end
    end
  end
end
