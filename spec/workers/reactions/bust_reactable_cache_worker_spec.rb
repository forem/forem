require "rails_helper"

RSpec.describe Reactions::BustReactableCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }
    let(:worker) { subject }
    let(:cache_bust) { instance_double(EdgeCache::Bust) }

    before do
      allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
      allow(cache_bust).to receive(:call)
    end

    it "busts the reactable article cache" do
      worker.perform(reaction.id)
      expect(cache_bust).to have_received(:call).with(user.path).once
      expect(cache_bust).to have_received(:call).with("/reactions?article_id=#{article.id}").once
    end

    it "busts the reactable comment cache" do
      worker.perform(comment_reaction.id)
      expect(cache_bust).to have_received(:call).with(user.path).once
      param = "/reactions?commentable_id=#{article.id}&commentable_type=Article"
      expect(cache_bust).to have_received(:call).with(param).once
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
