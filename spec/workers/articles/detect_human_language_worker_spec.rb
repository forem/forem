require "rails_helper"

RSpec.describe Articles::DetectHumanLanguageWorker, type: :worker do
  let(:worker) { subject }

  # Passing in a random article_id since the job won't actually run
  include_examples "#enqueues_on_correct_queue", "low_priority", [456]

  describe "#perform_now" do
    context "with article" do
      let_it_be(:article) { create(:article) }

      it "updates article language with detected language" do
        worker.perform(article.id)

        expect(article.language).to eql("en")
      end
    end

    context "without aritcle" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end
    end
  end
end
