describe KnapsackPro::TaskLoader do
  describe '#load_tasks' do
    let(:rspec_rake_task_path) { "#{KnapsackPro.root}/lib/tasks/rspec.rake" }
    let(:cucumber_rake_task_path) { "#{KnapsackPro.root}/lib/tasks/cucumber.rake" }
    let(:minitest_rake_task_path) { "#{KnapsackPro.root}/lib/tasks/minitest.rake" }

    before { allow(subject).to receive(:import) }
    after { subject.load_tasks }

    it { expect(subject).to receive(:import).with(rspec_rake_task_path) }
    it { expect(subject).to receive(:import).with(cucumber_rake_task_path) }
    it { expect(subject).to receive(:import).with(minitest_rake_task_path) }
  end
end
