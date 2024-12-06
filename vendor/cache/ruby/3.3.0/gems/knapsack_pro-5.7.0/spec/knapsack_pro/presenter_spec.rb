describe KnapsackPro::Presenter do
  describe '.global_time' do
    let(:tracker) { instance_double(KnapsackPro::Tracker, global_time: 60*62+3) }

    subject { described_class.global_time }

    before do
      expect(KnapsackPro).to receive(:tracker).and_return(tracker)
    end

    it { should eql "Global time execution for tests: 01h 02m 03s" }
  end

  describe '.pretty_seconds' do
    subject { described_class.pretty_seconds(seconds) }

    context 'when less then one second' do
      let(:seconds) { 0.987 }
      it { should eql '0.987s' }
    end

    context 'when one second' do
      let(:seconds) { 1 }
      it { should eql '01s' }
    end

    context 'when only seconds' do
      let(:seconds) { 5 }
      it { should eql '05s' }
    end

    context 'when only minutes' do
      let(:seconds) { 120 }
      it { should eql '02m' }
    end

    context 'when only hours' do
      let(:seconds) { 60*60*3 }
      it { should eql '03h' }
    end

    context 'when minutes and seconds' do
      let(:seconds) { 180+9 }
      it { should eql '03m 09s' }
    end

    context 'when all' do
      let(:seconds) { 60*60*4+120+7 }
      it { should eql '04h 02m 07s' }
    end

    context 'when negative seconds' do
      let(:seconds) { -67 }
      it { should eql '-01m 07s' }
    end
  end
end
