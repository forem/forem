require "rails_helper"

RSpec.describe Surveys::GenerateEmailContextWorker, type: :worker do
  describe "#perform" do
    let(:survey) { create(:survey, title: "Survey title", extra_email_context_paragraph: nil) }
    let!(:poll) { create(:poll, survey: survey, prompt_markdown: "Question 1") }
    let(:generator_instance) { instance_double(Ai::SurveyContextGenerator, call: "AI Generated Context") }

    before do
      stub_const("Ai::Base::DEFAULT_KEY", "some_key")
      allow(Ai::SurveyContextGenerator).to receive(:new).with(survey).and_return(generator_instance)
    end

    it "bails if survey is not found" do
      expect(Ai::SurveyContextGenerator).not_to receive(:new)
      described_class.new.perform(0)
    end

    it "bails if survey already has a context paragraph" do
      survey.update_column(:extra_email_context_paragraph, "Existing context")
      expect(Ai::SurveyContextGenerator).not_to receive(:new)
      described_class.new.perform(survey.id)
    end

    it "bails if survey has no polls" do
      survey.polls.destroy_all
      expect(Ai::SurveyContextGenerator).not_to receive(:new)
      described_class.new.perform(survey.id)
    end

    it "calls the generator and updates the survey when conditions are met" do
      described_class.new.perform(survey.id)
      expect(generator_instance).to have_received(:call)
      expect(survey.reload.extra_email_context_paragraph).to eq("AI Generated Context")
    end
  end
end
