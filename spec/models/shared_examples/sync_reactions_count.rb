RSpec.shared_examples "#sync_reactions_count" do |reactable_type|
  context "with syncable reactions count" do
    let(:reactable) { create(reactable_type) }

    before do
      create_list(:reaction, 4, points: 1, reactable: reactable)
      reaction = create(:reaction, reactable: reactable)
      reaction.update_column(:points, 0)
    end

    it "syncs reactions count" do
      reactable.update_column(:positive_reactions_count, 1)
      reactable.sync_reactions_count
      reactable.reload
      expect(reactable.positive_reactions_count).to eq(4)
    end
  end
end
