describe KnapsackPro::Hooks::Queue do
  describe '.call_before_queue' do
    subject { described_class.call_before_queue }

    context 'when callback is not set' do
      before do
        described_class.reset_before_queue
      end

      it { should be_nil }
    end

    context 'when callback is set multiple times' do
      let(:queue_id) { double }

      before do
        expect(KnapsackPro::Config::Env).to receive(:queue_id).twice.and_return(queue_id)

        $expected_called_blocks = []

        described_class.before_queue do |q_id|
          $expected_called_blocks << [:block_1_called, q_id]
        end
        described_class.before_queue do |q_id|
          $expected_called_blocks << [:block_2_called, q_id]
        end
      end

      it 'each block is called' do
        subject

        expect($expected_called_blocks).to eq([
          [:block_1_called, queue_id],
          [:block_2_called, queue_id],
        ])
      end
    end
  end

  describe '.call_before_subset_queue' do
    subject { described_class.call_before_subset_queue }

    context 'when callback is not set' do
      before do
        described_class.reset_before_subset_queue
      end

      it { should be_nil }
    end

    context 'when callback is set multiple times' do
      let(:queue_id) { double }
      let(:subset_queue_id) { double }

      before do
        expect(KnapsackPro::Config::Env).to receive(:queue_id).twice.and_return(queue_id)
        expect(KnapsackPro::Config::Env).to receive(:subset_queue_id).twice.and_return(subset_queue_id)

        $expected_called_blocks = []

        described_class.before_subset_queue do |q_id, subset_q_id|
          $expected_called_blocks << [:block_1_called, q_id, subset_q_id]
        end
        described_class.before_subset_queue do |q_id, subset_q_id|
          $expected_called_blocks << [:block_2_called, q_id, subset_q_id]
        end
      end

      it 'each block is called' do
        subject

        expect($expected_called_blocks).to eq([
          [:block_1_called, queue_id, subset_queue_id],
          [:block_2_called, queue_id, subset_queue_id],
        ])
      end
    end
  end

  describe '.call_after_subset_queue' do
    subject { described_class.call_after_subset_queue }

    context 'when callback is not set' do
      before do
        described_class.reset_after_subset_queue
      end

      it { should be_nil }
    end

    context 'when callback is set multiple times' do
      let(:queue_id) { double }
      let(:subset_queue_id) { double }

      before do
        expect(KnapsackPro::Config::Env).to receive(:queue_id).twice.and_return(queue_id)
        expect(KnapsackPro::Config::Env).to receive(:subset_queue_id).twice.and_return(subset_queue_id)

        $expected_called_blocks = []

        described_class.after_subset_queue do |q_id, subset_q_id|
          $expected_called_blocks << [:block_1_called, q_id, subset_q_id]
        end
        described_class.after_subset_queue do |q_id, subset_q_id|
          $expected_called_blocks << [:block_2_called, q_id, subset_q_id]
        end
      end

      it 'each block is called' do
        subject

        expect($expected_called_blocks).to eq([
          [:block_1_called, queue_id, subset_queue_id],
          [:block_2_called, queue_id, subset_queue_id],
        ])
      end
    end
  end

  describe '.call_after_queue' do
    subject { described_class.call_after_queue }

    context 'when callback is not set' do
      before do
        described_class.reset_after_queue
      end

      it { should be_nil }
    end

    context 'when callback is set multiple times' do
      let(:queue_id) { double }

      before do
        expect(KnapsackPro::Config::Env).to receive(:queue_id).twice.and_return(queue_id)

        $expected_called_blocks = []

        described_class.after_queue do |q_id|
          $expected_called_blocks << [:block_1_called, q_id]
        end
        described_class.after_queue do |q_id|
          $expected_called_blocks << [:block_2_called, q_id]
        end
      end

      it 'each block is called' do
        subject

        expect($expected_called_blocks).to eq([
          [:block_1_called, queue_id],
          [:block_2_called, queue_id],
        ])
      end
    end
  end
end
