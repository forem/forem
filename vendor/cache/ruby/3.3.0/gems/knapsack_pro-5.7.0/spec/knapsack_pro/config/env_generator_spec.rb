describe KnapsackPro::Config::EnvGenerator do
  describe '.set_queue_id' do
    subject { described_class.set_queue_id }

    context 'when queue id exists' do
      before do
        stub_const("ENV", { 'KNAPSACK_PRO_QUEUE_ID' => 'fake-queue-id' })
      end

      it do
        expect { subject }.to raise_error('Queue ID already generated.')
      end
    end

    context "when queue id doesn't exist" do
      before { stub_const("ENV", {}) }

      it do
        subject
        expect(ENV['KNAPSACK_PRO_QUEUE_ID']).not_to be_nil
      end

      it do
        now = DateTime.new(2016, 1, 9, 0, 0, 0)

        Timecop.freeze(now) do
          uuid = 'fake-uuid'
          expect(SecureRandom).to receive(:uuid).and_return(uuid)

          subject

          expect(ENV['KNAPSACK_PRO_QUEUE_ID']).to eq '1452297600_fake-uuid'
        end
      end
    end
  end

  describe '.set_subset_queue_id' do
    subject { described_class.set_subset_queue_id }

    before { stub_const("ENV", {}) }

    it do
      uuid = 'fake-uuid'
      expect(SecureRandom).to receive(:uuid).and_return(uuid)

      subject

      expect(ENV['KNAPSACK_PRO_SUBSET_QUEUE_ID']).to eq uuid
    end
  end
end
