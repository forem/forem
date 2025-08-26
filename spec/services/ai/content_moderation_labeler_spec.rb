require "rails_helper"

RSpec.describe Ai::ContentModerationLabeler, type: :service do
  let(:user) { create(:user, :trusted) }
  let(:article) { create(:article, user: user) }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
    allow(Settings::Community).to receive(:community_description).and_return("A community for developers.")
  end

  describe "#label" do
    context "when AI responds successfully" do
      before do
        allow(ai_client).to receive(:call).and_return("okay_and_on_topic")
      end

      it "returns the correct label" do
        result = described_class.new(article).label
        expect(result).to eq("okay_and_on_topic")
      end
    end

    context "when AI raises an error" do
      before do
        allow(ai_client).to receive(:call).and_raise(StandardError, "API Error")
      end

      it "falls back to safe default" do
        result = described_class.new(article).label
        expect(result).to eq("no_moderation_label")
      end
    end
  end
end
