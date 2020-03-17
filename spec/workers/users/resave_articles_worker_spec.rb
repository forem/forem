require "rails_helper"

RSpec.describe Users::ResaveArticlesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    context "with user" do
      let_it_be(:user) { create(:user) }
      let_it_be(:article) { create(:article, user: user) }

      it "resave articles" do
        old_updated_at = article.updated_at

        worker.perform(user.id)

        expect(article.reload.updated_at).to be > old_updated_at
      end
    end

    context "without user" do
      it "does not break" do
        expect { worker.perform(nil) }.not_to raise_error
      end
    end
  end
end
