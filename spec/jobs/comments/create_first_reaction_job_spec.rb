require "rails_helper"

RSpec.describe Comments::CreateFirstReactionJob, type: :job do
  include_examples "#enqueues_job", "comments_create_first_reaction", 1

  describe "#perform_now" do
    context "with comment" do
      let_it_be(:article) { create(:article) }
      let_it_be(:comment) { create(:comment, commentable: article) }

      it "creates a first reaction" do
        expect do
          described_class.perform_now(comment.id)
        end.to change(comment.reactions, :count).by(1)
      end

      it "creates a like reaction" do
        described_class.perform_now(comment.id)

        expect(comment.reactions.last.category).to eq("like")
      end
    end

    context "without comment" do
      it "does not break" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end
    end
  end
end
