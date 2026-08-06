require "rails_helper"

RSpec.describe Ai::AppealAssessor do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:appeal) { create(:flag_appeal, user: user, appealable: article, reason: "False positive on code snippet.") }
  let(:assessor) { described_class.new(appeal) }

  describe "#evaluate" do
    let(:ai_client_double) { instance_double(Ai::Base) }

    before do
      allow(Ai::Base).to receive(:new).and_return(ai_client_double)
    end

    it "parses valid JSON response from Gemini" do
      response_json = {
        recommendation: "auto_unflag",
        confidence_score: 0.95,
        summary: "Legitimate code snippet false positive."
      }.to_json

      allow(ai_client_double).to receive(:call).and_return(response_json)

      result = assessor.evaluate

      expect(result[:recommendation]).to eq("auto_unflag")
      expect(result[:confidence_score]).to eq(0.95)
      expect(result[:summary]).to eq("Legitimate code snippet false positive.")
    end

    it "returns fallback on API failure" do
      allow(ai_client_double).to receive(:call).and_raise(StandardError, "API Error")

      result = assessor.evaluate

      expect(result[:recommendation]).to eq("human_review")
      expect(result[:confidence_score]).to eq(0.5)
    end

    it "evaluates appeal when target is a User profile" do
      user_appeal = create(:flag_appeal, user: user, appealable: user, reason: "Account flagged in error.")
      user_assessor = described_class.new(user_appeal)
      response_json = {
        recommendation: "human_review",
        confidence_score: 0.70,
        summary: "Profile context assessed."
      }.to_json

      allow(ai_client_double).to receive(:call).and_return(response_json)

      result = user_assessor.evaluate
      expect(result[:recommendation]).to eq("human_review")
    end
  end
end
