require 'rails_helper'

RSpec.describe Mentions::CreateAllJob do
  let(:comment) { create(:comment, commentable: create(:article)) }

  describe ".perform_later" do
    it "add job to queue :mentions_create_all" do
      expect do
        described_class.perform_later(1, "Comment")
      end.to have_enqueued_job.with(1, "Comment").on_queue("mentions_create_all")
    end
  end

  describe "#perform" do
    it 'calls on MentionsCreateAllService' do
      described_class.new.perform(comment.id, comment.class.name) do
        expect(MentionsCreateAllService).to have_received(:call).with(comment)
      end
    end
  end
end
