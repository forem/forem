shared_examples 'adapter' do
  describe '#bind_time_tracker' do
    it do
      expect {
        subject.bind_time_tracker
      }.not_to raise_error
    end
  end

  describe '#bind_save_report' do
    it do
      expect {
        subject.bind_save_report
      }.not_to raise_error
    end
  end
end
