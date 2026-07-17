require "rails_helper"

RSpec.describe Comments::GenerateEmbeddingWorker, type: :worker do
  let(:comment) { create(:comment) }

  describe "#perform" do
    before do
      comment.update_columns(score: 3)
    end

    it "generates and saves an embedding, then queues the record classifier worker" do
      client_double = instance_double(Ai::Embedding)
      allow(Ai::Embedding).to receive(:new).and_return(client_double)
      allow(client_double).to receive(:call).and_return(Array.new(768, 0.1))

      allow(Concepts::ClassifyRecordWorker).to receive(:perform_async)

      described_class.new.perform(comment.id)

      expect(comment.reload.semantic_embedding).to eq(Array.new(768, 0.1))
      expect(Concepts::ClassifyRecordWorker).to have_received(:perform_async).with("Comment", comment.id)
    end

    it "does nothing if the comment score is less than 3" do
      comment.update_columns(score: 2)
      expect(Ai::Embedding).not_to receive(:new)

      described_class.new.perform(comment.id)
    end

    it "does nothing if the embedding is already present" do
      comment.update_columns(semantic_embedding: Array.new(768, 0.1))
      expect(Ai::Embedding).not_to receive(:new)

      described_class.new.perform(comment.id)
    end
  end
end
