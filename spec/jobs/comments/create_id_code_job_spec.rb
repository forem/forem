require "rails_helper"

RSpec.describe Comments::CreateIdCodeJob, type: :job do
  include_examples "#enqueues_job", "comments_create_id_code", 1

  describe "#perform_now" do
    context "with comment" do
      let_it_be(:article) { create(:article) }
      let_it_be(:comment) { create(:comment, commentable: article) }

      it "creates an id code" do
        described_class.perform_now(comment.id)

        expect(comment.reload.id_code).to eq(comment.id.to_s(26))
      end
    end

    context "without comment" do
      it "does not break" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end
    end
  end
end
