require "rails_helper"

RSpec.describe Reactions::BustReactableCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }
    let(:worker) { subject }

    before do
      allow(EdgeCache::Bust).to receive(:call)
    end

    it "busts the reactable article cache" do
      worker.perform(reaction.id)
      expect(EdgeCache::Bust).to have_received(:call).with(user.path).once
      expect(EdgeCache::Bust).to have_received(:call).with("/reactions?article_id=#{article.id}").once
    end

    it "busts the reactable comment cache" do
      worker.perform(comment_reaction.id)
      expect(EdgeCache::Bust).to have_received(:call).with(user.path).once
      param = "/reactions?commentable_id=#{article.id}&commentable_type=Article"
      expect(EdgeCache::Bust).to have_received(:call).with(param).once
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
