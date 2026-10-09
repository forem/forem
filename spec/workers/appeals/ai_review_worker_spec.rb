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

    it "auto-resolves appeal when AI recommends auto_unflag above a lowered threshold" do
      allow(Settings::General).to receive(:appeal_auto_unflag_threshold).and_return(0.9)
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

    it "routes even a fully confident auto_unflag to human review under the default threshold" do
      expect(Settings::General.appeal_auto_unflag_threshold).to eq(1.01)
      allow(assessor_double).to receive(:evaluate).and_return(
        summary: "Certain false positive.",
        confidence_score: 1.0,
        recommendation: "auto_unflag",
      )

      described_class.new.perform(appeal.id)

      appeal.reload
      expect(appeal.status).to eq("ai_reviewed")
      expect(appeal.ai_summary).to eq("Certain false positive.")
      expect(appeal.ai_recommendation).to eq("auto_unflag")
      expect(Appeals::Resolver).not_to have_received(:approve)
    end

    it "never auto-resolves when the threshold is unset" do
      allow(Settings::General).to receive(:appeal_auto_unflag_threshold).and_return(nil)
      allow(assessor_double).to receive(:evaluate).and_return(
        summary: "Certain false positive.",
        confidence_score: 1.0,
        recommendation: "auto_unflag",
      )

      described_class.new.perform(appeal.id)

      expect(Appeals::Resolver).not_to have_received(:approve)
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

    context "when the appealed content was deleted while the appeal was pending" do
      let(:article) { create(:article, user: user) }
      let(:appeal) { create(:flag_appeal, user: user, appealable: article, status: :open) }

      before do
        # Use the real assessor, even if the AI would have wanted to auto-unflag.
        allow(Ai::AppealAssessor).to receive(:new).and_call_original
        allow(Ai::Base).to receive(:new)
      end

      it "routes to human review without raising and never auto-resolves" do
        appeal_id = appeal.id
        article.delete

        expect { described_class.new.perform(appeal_id) }.not_to raise_error

        orphaned = FlagAppeal.find(appeal_id)
        expect(orphaned.status).to eq("ai_reviewed")
        expect(orphaned.ai_recommendation).to eq("human_review")
        expect(Ai::Base).not_to have_received(:new)
        expect(Appeals::Resolver).not_to have_received(:approve)
      end
    end
  end
end
