shared_examples_for 'Rpush::Client::ActiveRecord::Notification' do
  let(:notification) { described_class.new }

  it 'allows assignment of a single registration ID' do
    notification.registration_ids = 'a'
    expect(notification.registration_ids).to eq ['a']
  end

  describe 'when assigning data for the device' do
    before { allow(Rpush::Deprecation).to receive(:warn) }

    it 'calls MultiJson.dump when multi_json responds to :dump' do
      allow(MultiJson).to receive(:respond_to?).with(:dump).and_return(true)
      expect(MultiJson).to receive(:dump).with(any_args)
      notification.data = { pirates: 1 }
    end

    it 'calls MultiJson.encode when multi_json does not respond to :dump' do
      allow(MultiJson).to receive(:respond_to?).with(:dump).and_return(false)
      expect(MultiJson).to receive(:encode).with(any_args)
      notification.data = { ninjas: 1 }
    end

    it 'raises an ArgumentError if something other than a Hash is assigned' do
      expect do
        notification.data = []
      end.to raise_error(ArgumentError, 'must be a Hash')
    end

    it 'encodes the given Hash as JSON' do
      notification.data = { hi: 'mom' }
      expect(notification.read_attribute(:data)).to eq('{"hi":"mom"}')
    end

    it 'decodes the JSON when using the reader method' do
      notification.data = { hi: 'mom' }
      expect(notification.data).to eq('hi' => 'mom')
    end
  end

  describe 'when assigning the notification payload for the device' do
    it 'raises an ArgumentError if something other than a Hash is assigned' do
      expect do
        notification.notification = []
      end.to raise_error(ArgumentError, 'must be a Hash')
    end

    it 'encodes the given Hash as JSON' do
      notification.notification = { hi: 'dad' }
      expect(notification.read_attribute(:notification)).to eq('{"hi":"dad"}')
    end

    it 'decodes the JSON when using the reader method' do
      notification.notification = { hi: 'dad' }
      expect(notification.notification).to eq('hi' => 'dad')
    end
  end
end
