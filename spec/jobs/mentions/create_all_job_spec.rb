require "rails_helper"

RSpec.describe Mentions::CreateAllJob do
  let(:comment) { create(:comment, commentable: create(:article)) }

  include_examples "#enqueues_job", "mentions_create_all", 1

  describe "#perform" do
    it "calls on Mentions::CreateAll" do
      allow(Mentions::CreateAll).to receive(:call).with(comment)

      described_class.new.perform(comment.id, comment.class.name)

      expect(Mentions::CreateAll).to have_received(:call).with(comment)
    end
  end
end
