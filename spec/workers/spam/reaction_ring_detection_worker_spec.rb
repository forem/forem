# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spam::ReactionRingDetectionWorker, type: :worker do
  let(:user) { create(:user) }

  describe "#perform" do
    context "when user does not exist" do
      it "returns early" do
        expect(Spam::ReactionRingDetector).not_to receive(:new)
        described_class.new.perform(999999)
      end
    end

    context "when user has insufficient reactions" do
      before do
        create_list(:reaction, 30, user: user, reactable_type: "Article", category: "like", created_at: 2.months.ago)
      end

      it "returns early without running detection" do
        expect(Spam::ReactionRingDetector).not_to receive(:new)
        described_class.new.perform(user.id)
      end
    end

    context "when user is admin" do
      let(:user) { create(:user, :admin) }

      before do
        create_list(:reaction, 60, user: user, reactable_type: "Article", category: "like", created_at: 2.months.ago)
      end

      it "returns early without running detection" do
        expect(Spam::ReactionRingDetector).not_to receive(:new)
        described_class.new.perform(user.id)
      end
    end

    context "when user is trusted" do
      let(:user) { create(:user, :trusted) }

      before do
        create_list(:reaction, 60, user: user, reactable_type: "Article", category: "like", created_at: 2.months.ago)
      end

      it "returns early without running detection" do
        expect(Spam::ReactionRingDetector).not_to receive(:new)
        described_class.new.perform(user.id)
      end
    end

    context "when user meets criteria for analysis" do
      before do
        create_list(:reaction, 60, user: user, reactable_type: "Article", category: "like", created_at: 2.months.ago)
      end

      it "runs the ring detection" do
        detector = instance_double(Spam::ReactionRingDetector)
        allow(Spam::ReactionRingDetector).to receive(:new).with(user.id).and_return(detector)
        allow(detector).to receive(:call).and_return(false)

        described_class.new.perform(user.id)

        expect(Spam::ReactionRingDetector).to have_received(:new).with(user.id)
        expect(detector).to have_received(:call)
      end

      context "when ring is detected" do
        it "logs the detection" do
          detector = instance_double(Spam::ReactionRingDetector)
          allow(Spam::ReactionRingDetector).to receive(:new).with(user.id).and_return(detector)
          allow(detector).to receive(:call).and_return(true)

          expect(Rails.logger).to receive(:info).with("Reaction ring detected for user #{user.id}")
          expect(Rails.logger).to receive(:info).with("Reaction ring detected for user #{user.id} - moderators should be notified")

          described_class.new.perform(user.id)
        end
      end

      context "when no ring is detected" do
        it "does not log detection" do
          detector = instance_double(Spam::ReactionRingDetector)
          allow(Spam::ReactionRingDetector).to receive(:new).with(user.id).and_return(detector)
          allow(detector).to receive(:call).and_return(false)

          expect(Rails.logger).not_to receive(:info).with("Reaction ring detected for user #{user.id}")

          described_class.new.perform(user.id)
        end
      end
    end
  end
end
