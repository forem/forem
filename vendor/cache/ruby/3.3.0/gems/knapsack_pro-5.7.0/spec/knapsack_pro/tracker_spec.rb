shared_examples 'default trakcer attributes' do
  it { expect(tracker.global_time).to eql 0 }
  it { expect(tracker.test_files_with_time).to eql({}) }
  it { expect(tracker.prerun_tests_loaded).to be false }
end

describe KnapsackPro::Tracker do
  let(:adapter) { 'RSpecAdapter' }
  let(:tracker) { described_class.send(:new) }

  before do
    allow(KnapsackPro::Config::Env).to receive(:test_runner_adapter).and_return(adapter)
    allow(KnapsackPro::Config::Env).to receive(:ci_node_index).and_return(0)
  end

  it_behaves_like 'default trakcer attributes'

  describe '#current_test_path' do
    subject { tracker.current_test_path }

    context 'when current_test_path not set' do
      it { should eql nil }
    end

    context 'when current_test_path set' do
      context 'when current_test_path has prefix ./' do
        before { tracker.current_test_path = './spec/models/user_spec.rb' }
        it { should eql 'spec/models/user_spec.rb' }
      end

      context 'when current_test_path has no prefix ./' do
        before { tracker.current_test_path = 'spec/models/user_spec.rb' }
        it { should eql 'spec/models/user_spec.rb' }
      end
    end
  end

  describe 'track time execution' do
    let(:test_paths) { ['a_spec.rb', 'b_spec.rb'] }
    let(:delta) { 0.02 }

    before do
      tracker.set_prerun_tests(test_paths)
    end

    shared_examples '#to_a' do
      subject { tracker.to_a }

      its(:size) { should eq 2 }
      it { expect(subject[0][:path]).to eq 'a_spec.rb' }
      it { expect(subject[0][:time_execution]).to be >= 0 }
      it { expect(subject[1][:path]).to eq 'b_spec.rb' }
      it { expect(subject[1][:time_execution]).to be >= 0 }
    end

    context 'without Timecop' do
      before do
        test_paths.each_with_index do |test_path, index|
          tracker.current_test_path = test_path
          tracker.start_timer
          sleep index.to_f / 10 + 0.1
          tracker.stop_timer
        end
      end

      it { expect(tracker.global_time).to be_within(delta).of(0.3) }
      it { expect(tracker.prerun_tests_loaded).to be true }
      it { expect(tracker.test_files_with_time.keys.size).to eql 2 }
      it { expect(tracker.test_files_with_time['a_spec.rb'][:time_execution]).to be_within(delta).of(0.1) }
      it { expect(tracker.test_files_with_time['b_spec.rb'][:time_execution]).to be_within(delta).of(0.2) }
      it_behaves_like '#to_a'
    end

    context "with Timecop - Timecop shouldn't have impact on the measured test time" do
      let(:now) { Time.now }

      before do
        test_paths.each_with_index do |test_path, index|
          Timecop.freeze(now) do
            tracker.current_test_path = test_path
            tracker.start_timer
          end

          delay = index + 1
          Timecop.freeze(now+delay) do
            tracker.stop_timer
          end
        end
      end

      it { expect(tracker.global_time).to be > 0 }
      it { expect(tracker.global_time).to be_within(delta).of(0) }
      it { expect(tracker.prerun_tests_loaded).to be true }
      it { expect(tracker.test_files_with_time.keys.size).to eql 2 }
      it { expect(tracker.test_files_with_time['a_spec.rb'][:time_execution]).to be_within(delta).of(0) }
      it { expect(tracker.test_files_with_time['b_spec.rb'][:time_execution]).to be_within(delta).of(0) }
      it_behaves_like '#to_a'
    end

    # https://github.com/KnapsackPro/knapsack_pro-ruby/issues/32
    context 'when start timer was not called (rspec-retry issue)' do
      before do
        test_paths.each_with_index do |test_path, index|
          tracker.current_test_path = test_path
          sleep 0.001
          tracker.stop_timer
        end
      end

      it { expect(tracker.global_time).to be > 0 }
      it { expect(tracker.prerun_tests_loaded).to be true }
      it { expect(tracker.test_files_with_time.keys.size).to eql 2 }
      it { expect(tracker.test_files_with_time['a_spec.rb'][:time_execution]).to eq 0 }
      it '2nd spec (b_spec.rb) should have recorded time execution - because start_time was set during first call of stop_timer for the first spec (a_spec.rb)' do
        expect(tracker.test_files_with_time['b_spec.rb'][:time_execution]).to be > 0
      end
      it_behaves_like '#to_a'
    end

    context 'when a new tracker instance is created' do
      let(:non_pending_test_paths) { ['a_spec.rb', 'b_spec.rb'] }
      let(:test_paths) { non_pending_test_paths + ['pending_spec.rb'] }

      before do
        # measure tests only for non pending tests
        non_pending_test_paths.each_with_index do |test_path, index|
          tracker.current_test_path = test_path
          tracker.start_timer
          sleep index.to_f / 10 + 0.1
          tracker.stop_timer
        end
      end

      it '2nd tracker instance loads prerun tests from the disk' do
        expect(tracker.prerun_tests_loaded).to be true
        expect(tracker.to_a.size).to eq 3
        expect(tracker.to_a[0][:path]).to eq 'a_spec.rb'
        expect(tracker.to_a[0][:time_execution]).to be >= 0
        expect(tracker.to_a[1][:path]).to eq 'b_spec.rb'
        expect(tracker.to_a[1][:time_execution]).to be >= 0
        expect(tracker.to_a[2][:path]).to eq 'pending_spec.rb'
        expect(tracker.to_a[2][:time_execution]).to eq 0

        tracker2 = described_class.send(:new)
        expect(tracker2.prerun_tests_loaded).to be false
        expect(tracker2.to_a.size).to eq 3
        expect(tracker2.to_a[0][:path]).to eq 'a_spec.rb'
        expect(tracker2.to_a[0][:time_execution]).to be >= 0
        expect(tracker2.to_a[1][:path]).to eq 'b_spec.rb'
        expect(tracker2.to_a[1][:time_execution]).to be >= 0
        expect(tracker2.to_a[2][:path]).to eq 'pending_spec.rb'
        expect(tracker2.to_a[2][:time_execution]).to eq 0
        expect(tracker2.prerun_tests_loaded).to be true
      end
    end
  end

  describe '#reset!' do
    let(:test_file_path) { 'a_spec.rb' }

    before do
      tracker.set_prerun_tests([test_file_path])
    end

    before do
      expect(tracker.prerun_tests_loaded).to be true

      tracker.current_test_path = test_file_path
      tracker.start_timer
      sleep 0.1
      tracker.stop_timer

      expect(tracker.global_time).not_to eql 0

      tracker.reset!
    end

    it_behaves_like 'default trakcer attributes'

    it "global time since beginning won't be reset" do
      expect(tracker.global_time_since_beginning).to be >= 0.1
    end

    it 'resets prerun_tests_loaded to false' do
      expect(tracker.prerun_tests_loaded).to be false
    end
  end


  describe '#unexecuted_test_files' do
    before do
      tracker.set_prerun_tests(['a_spec.rb', 'b_spec.rb', 'c_spec.rb'])

      # measure execution time for b_spec.rb
      tracker.current_test_path = 'b_spec.rb'
      tracker.start_timer
      sleep 0.1
      tracker.stop_timer
    end

    it 'returns test files without measured time' do
      expect(tracker.unexecuted_test_files).to eq(['a_spec.rb', 'c_spec.rb'])
    end
  end
end
