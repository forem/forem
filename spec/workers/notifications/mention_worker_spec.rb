require "rails_helper"
RSpec.describe Notifications::MentionWorker, type: :worker do
  describe "#perform" do
    let(:mention) { create(:mention, mentionable: create(:comment, commentable: create(:article))) }
    let(:service) { Notifications::NewMention::Send }
    let(:worker) { subject }

    before do
      allow(service).to receive(:call)
    end

    it "calls a service" do
      worker.perform(mention.id)
      expect(service).to have_received(:call).with(mention).once
    end

    it "does nothing for non-existent mention" do
      worker.perform(nil)
      expect(service).not_to have_received(:call)
    end
  end
end
