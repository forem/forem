RSpec.describe 'OrderGroup' do
  let(:order_group) { ::RSpec::Mocks::OrderGroup.new }

  describe '#consume' do
    let(:ordered_1) { double :ordered? => true }
    let(:ordered_2) { double :ordered? => true }
    let(:unordered) { double :ordered? => false }

    before do
      order_group.register unordered
      order_group.register ordered_1
      order_group.register unordered
      order_group.register ordered_2
      order_group.register unordered
      order_group.register unordered
    end

    it 'returns the first ordered? expectation' do
      expect(order_group.consume).to eq ordered_1
    end
    it 'keeps returning ordered? expectation until all are returned' do
      expectations = 3.times.map { order_group.consume }
      expect(expectations).to eq [ordered_1, ordered_2, nil]
    end
  end
end
