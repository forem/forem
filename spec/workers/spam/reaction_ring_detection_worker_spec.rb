require "rails_helper"

RSpec.describe Spam::ReactionRingDetectionWorker, type: :worker do
  let(:user) { create(:user) }
  let(:author) { create(:user) }

  before do
    allow(Spam::ReactionRingDetector).to receive(:new).and_call_original
  end

  def create_article_reactions(count, created_at: 2.months.ago)
    Array.new(count) do
      article = create(:article, user: author, published: true, tags: "")
      create(:reaction, user: user, reactable: article, category: "like", created_at: created_at)
    end
  end

  describe "#perform" do
    context "when user does not exist" do
      it "returns early" do
        described_class.new.perform(999_999)
        expect(Spam::ReactionRingDetector).not_to have_received(:new)
      end
    end

    context "when user has insufficient reactions" do
      before do
        stub_const("Spam::ReactionRingDetector::MIN_REACTIONS_THRESHOLD", 5)
        create_article_reactions(4)
      end

      it "returns early without running detection" do
        described_class.new.perform(user.id)
        expect(Spam::ReactionRingDetector).not_to have_received(:new)
      end
    end

    context "when user is admin" do
      let(:user) { create(:user, :admin) }

      it "returns early without running detection" do
        described_class.new.perform(user.id)
        expect(Spam::ReactionRingDetector).not_to have_received(:new)
      end
    end

    context "when user is trusted" do
      let(:user) { create(:user, :trusted) }

      it "returns early without running detection" do
        described_class.new.perform(user.id)
        expect(Spam::ReactionRingDetector).not_to have_received(:new)
      end
    end

    context "when user meets criteria for analysis" do
      before do
        stub_const("Spam::ReactionRingDetector::MIN_REACTIONS_THRESHOLD", 5)
        create_article_reactions(5)
        allow(Rails.logger).to receive(:info)
      end

      it "runs detection and logs when a ring is detected", :aggregate_failures do
        detector = instance_double(Spam::ReactionRingDetector, call: true)
        allow(Spam::ReactionRingDetector).to receive(:new).with(user.id).and_return(detector)

        described_class.new.perform(user.id)

        expect(Spam::ReactionRingDetector).to have_received(:new).with(user.id)
        expect(detector).to have_received(:call)
        expect(Rails.logger).to have_received(:info).with("Reaction ring detected for user #{user.id}")
        expect(Rails.logger).to have_received(:info)
          .with("Reaction ring detected for user #{user.id} - moderators should be notified")
      end

      it "runs detection and does not log when no ring is detected", :aggregate_failures do
        detector = instance_double(Spam::ReactionRingDetector, call: false)
        allow(Spam::ReactionRingDetector).to receive(:new).with(user.id).and_return(detector)

        described_class.new.perform(user.id)

        expect(Spam::ReactionRingDetector).to have_received(:new).with(user.id)
        expect(detector).to have_received(:call)
        expect(Rails.logger).not_to have_received(:info).with("Reaction ring detected for user #{user.id}")
      end
    end
  end
end
