require "rails_helper"

RSpec.describe Mention, type: :model do
  let_it_be(:comment) { create(:comment, commentable: create(:podcast_episode)) }

  describe "#create_all" do
    it "enqueues a job to create mentions" do
      assert_enqueued_with(job: Mentions::CreateAllJob, args: [comment.id, "Comment"], queue: "mentions_create_all") do
        described_class.create_all(comment)
      end
    end
  end
end
