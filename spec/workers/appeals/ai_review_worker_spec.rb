require "rails_helper"

RSpec.describe Appeals::AiReviewWorker, type: :worker do
  let(:user) { create(:user) }
  let(:appeal) { create(:flag_appeal, user: user, status: :open) }
  let(:assessor_double) { instance_double(Ai::AppealAssessor) }

  before do
    allow(Ai::AppealAssessor).to receive(:new).with(appeal).and_return(assessor_double)
    allow(Appeals::Resolver).to receive(:approve)
  end

  describe "#perform" do
    it "updates appeal with AI evaluation results when recommendation is human_review" do
      allow(assessor_double).to receive(:evaluate).and_return(
        summary: "Needs human review.",
        confidence_score: 0.65,
        recommendation: "human_review",
      )

      described_class.new.perform(appeal.id)

      appeal.reload
      expect(appeal.ai_summary).to eq("Needs human review.")
      expect(appeal.ai_confidence_score).to eq(0.65)
      expect(appeal.ai_recommendation).to eq("human_review")
      expect(appeal.status).to eq("ai_reviewed")
    end

    it "auto-resolves appeal when AI recommends auto_unflag with high confidence" do
      allow(assessor_double).to receive(:evaluate).and_return(
        summary: "High confidence false positive.",
        confidence_score: 0.95,
        recommendation: "auto_unflag",
      )

      described_class.new.perform(appeal.id)

      appeal.reload
      expect(appeal.status).to eq("ai_reviewed")
      expect(Appeals::Resolver).to have_received(:approve).with(appeal: appeal)
    end

    it "does not update or resolve if appeal is no longer open after evaluation (reload guard)" do
      allow(assessor_double).to receive(:evaluate) do
        appeal.update!(status: :approved)
        {
          summary: "Late evaluation.",
          confidence_score: 0.95,
          recommendation: "auto_unflag"
        }
      end

      described_class.new.perform(appeal.id)

      appeal.reload
      expect(appeal.ai_summary).not_to eq("Late evaluation.")
      expect(Appeals::Resolver).not_to have_received(:approve)
    end

    it "returns early if appeal is not found or not open initially" do
      appeal.update!(status: :rejected)

      described_class.new.perform(appeal.id)

      expect(Ai::AppealAssessor).not_to have_received(:new)
    end
  end
end
