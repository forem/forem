require "rails_helper"

RSpec.describe Space do
  let(:space) { described_class.new(limit_post_creation_to_admins: limit_post_creation_to_admins) }
  let(:limit_post_creation_to_admins) { true }

  describe "#to_param" do
    subject(:to_param) { space.to_param }

    it { is_expected.to eq(described_class::DEFAULT) }
  end

  describe "#save" do
    subject(:save) { space.save }

    before do
      allow(Spaces::BustCachesForSpaceChangeWorker).to receive(:perform_async)
    end

    it { is_expected.to be_truthy }

    context "when limit_post_creation_to_admins is true" do
      let(:limit_post_creation_to_admins) { true }

      it "enables limit_post_creation_to_admins FeatureFlag" do
        save
        expect(FeatureFlag.enabled?(:limit_post_creation_to_admins)).to be(true)
      end
    end

    context "when limit_post_creation_to_admins is false" do
      let(:limit_post_creation_to_admins) { false }

      it "disables limit_post_creation_to_admins FeatureFlag" do
        save
        expect(FeatureFlag.enabled?(:limit_post_creation_to_admins)).to be(false)
      end
    end

    it "busts the caches that impact the space" do
      save

      expect(Spaces::BustCachesForSpaceChangeWorker).to have_received(:perform_async)
    end
  end
end
