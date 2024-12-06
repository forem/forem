describe KnapsackPro::Runners::Queue::BaseRunner do
  describe '.run' do
    it do
      expect {
        described_class.run(nil)
      }.to raise_error NotImplementedError
    end
  end

  describe '.run_tests' do
    it do
      expect {
        described_class.run_tests(nil, nil, nil, nil)
      }.to raise_error NotImplementedError
    end
  end

  describe 'instance methods' do
    let(:adapter_class) { double }
    let(:runner) do
      described_class.new(adapter_class)
    end
    let(:allocator) { instance_double(KnapsackPro::QueueAllocator) }
    let(:allocator_builder) { instance_double(KnapsackPro::QueueAllocatorBuilder) }

    before do
      expect(KnapsackPro::QueueAllocatorBuilder).to receive(:new).with(adapter_class).and_return(allocator_builder)
      expect(allocator_builder).to receive(:allocator).and_return(allocator)
    end

    describe '#test_file_paths' do
      subject { runner.test_file_paths(args) }

      context 'when can_initialize_queue flag has value' do
        let(:can_initialize_queue) { double }
        let(:executed_test_files) { double }
        let(:args) do
          {
            can_initialize_queue: can_initialize_queue,
            executed_test_files: executed_test_files,
          }
        end
        let(:test_file_paths) { double }

        before do
          expect(allocator).to receive(:test_file_paths).with(can_initialize_queue, executed_test_files).and_return(test_file_paths)
        end

        it { should eq test_file_paths }
      end

      context 'when can_initialize_queue flag has no value' do
        let(:args) { {} }

        it do
          expect { subject }.to raise_error(KeyError)
        end
      end
    end

    describe '#test_dir' do
      let(:test_dir) { double }

      subject { runner.test_dir }

      before do
        expect(allocator_builder).to receive(:test_dir).and_return(test_dir)
      end

      it { should eq test_dir }
    end
  end
end
