RSpec.shared_examples "#sync_reactions_count" do |reactable_type|
  context "with syncable reactions count" do
    let(:reactable) { create(reactable_type) }

    before do
      create(:reaction, points: 1, reactable: reactable)
      create(:reaction, points: 0, reactable: reactable)
    end

    it "syncs reactions count" do
      expect(reactable.positive_reactions_count).to eq(0)
      reactable.sync_reactions_count
      reactable.reload
      expected_count = reactable.reactions.positive.size
      expect(reactable.positive_reactions_count).to eq(expected_count)
    end
  end
end
