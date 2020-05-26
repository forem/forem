RSpec.shared_examples "#sync_reactions_count" do |reactable_type|
  context "with syncable reactions count" do
    let(:reactable) { create(reactable_type) }

    before do
      create(:reaction, points: 1, reactable: reactable)
      create(:reaction, points: 0, reactable: reactable)
    end

    it "syncs reactions count" do
      expect(reactable.public_reactions_count).to eq(0)
      reactable.sync_reactions_count
      reactable.reload
      expected_count = reactable.reactions.public_category.size
      expect(reactable.public_reactions_count).to eq(expected_count)
    end
  end
end
