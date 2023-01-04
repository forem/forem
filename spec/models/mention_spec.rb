require "rails_helper"

RSpec.describe Mention do
  let(:comment) { create(:comment, commentable: create(:podcast_episode)) }

  describe "#create_all" do
    it "enqueues a job to default queue" do
      expect do
        described_class.create_all(comment)
      end.to change(Mentions::CreateAllWorker.jobs, :size).by(1)
    end
  end

  # TODO: Replace this test with validation spec
  it "creates a valid mention" do
    expect(create(:mention)).to be_valid
  end

  # TODO: Replace this test with validation spec
  it "doesn't raise undefined method for NilClass on valid?" do
    expect(described_class.new.valid?).to be(false)
  end
end
