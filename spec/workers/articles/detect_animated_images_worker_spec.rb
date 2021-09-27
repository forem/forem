require "rails_helper"

RSpec.describe Articles::DetectAnimatedImagesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with article" do
      let(:article) { double }
      let(:article_id) { 1 }

      before do
        allow(Article).to receive(:find_by).with(id: article_id).and_return(article)
        allow(EdgeCache::BustArticle).to receive(:call).with(article)
      end

      it "calls only Articles::DetectAnimatedImages", :aggregate_failures do
        allow(Articles::DetectAnimatedImages).to receive(:call).with(article).and_return(false)

        worker.perform(article_id)

        expect(Articles::DetectAnimatedImages).to have_received(:call).with(article)
        expect(EdgeCache::BustArticle).not_to have_received(:call).with(article)
      end

      it "calls both Articles::DetectAnimatedImages and EdgeCache::BustArticle if an animated image is detected",
         :aggregate_failures do
        allow(Articles::DetectAnimatedImages).to receive(:call).with(article).and_return(true)

        worker.perform(article_id)

        expect(Articles::DetectAnimatedImages).to have_received(:call).with(article)
        expect(EdgeCache::BustArticle).to have_received(:call).with(article)
      end
    end

    context "without article" do
      before do
        allow(Articles::DetectAnimatedImages).to receive(:call).and_return(true)
        allow(EdgeCache::BustArticle).to receive(:call)
      end

      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not call Articles::DetectAnimatedImages" do
        worker.perform(nil)

        expect(Articles::DetectAnimatedImages).not_to have_received(:call)
      end

      it "does not call EdgeCache::BustArticle" do
        worker.perform(nil)

        expect(EdgeCache::BustArticle).not_to have_received(:call)
      end
    end
  end
end
