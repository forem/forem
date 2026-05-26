require "rails_helper"

RSpec.describe GenerateArticleEmbeddingWorker, type: :worker do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  describe "#perform" do
    it "generates and saves an embedding, then queues the user interest worker" do
      client_double = instance_double(Ai::Embedding)
      allow(Ai::Embedding).to receive(:new).and_return(client_double)
      allow(client_double).to receive(:call).and_return(Array.new(768, 0.1))

      allow(UpdateUserInterestEmbeddingWorker).to receive(:perform_async)

      described_class.new.perform(article.id)

      expect(article.reload.semantic_embedding).to eq(Array.new(768, 0.1))
      expect(UpdateUserInterestEmbeddingWorker).to have_received(:perform_async).with(user.id, article.id)
    end

    it "does nothing if the article is unpublished" do
      article.update_column(:published, false)
      expect(Ai::Embedding).not_to receive(:new)
      
      described_class.new.perform(article.id)
    end
  end
end
