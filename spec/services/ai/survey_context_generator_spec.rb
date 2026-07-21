require "rails_helper"

RSpec.describe Ai::SurveyContextGenerator, type: :service do
  let(:survey) { create(:survey, title: "App Performance Monitoring Survey") }
  let!(:poll1) { create(:poll, survey: survey, prompt_markdown: "What is your main APM tool?") }
  let!(:poll2) { create(:poll, survey: survey, prompt_markdown: "How satisfied are you with its latency tracking?") }
  
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
  end

  describe "#call" do
    context "when AI call is successful" do
      before do
        allow(ai_client).to receive(:call).and_return("  This is *very quick* two-question private survey to understand your current opinions on the app monitoring landscape  ")
      end

      it "returns the stripped AI response" do
        generator = described_class.new(survey)
        expect(generator.call).to eq("This is *very quick* two-question private survey to understand your current opinions on the app monitoring landscape")
      end

      it "constructs a prompt containing the survey title and poll count" do
        generator = described_class.new(survey)
        prompt = generator.send(:build_prompt)

        expect(prompt).to include("App Performance Monitoring Survey")
        expect(prompt).to include("Number of questions: 2")
        expect(prompt).to include("Question 1: What is your main APM tool?")
        expect(prompt).to include("Question 2: How satisfied are you with its latency tracking?")
        expect(prompt).to include("This is *very quick* {number_of_questions}-question private survey to understand {topic_of_the_survey}")
      end
    end

    context "when AI call raises an error" do
      before do
        allow(ai_client).to receive(:call).and_raise(StandardError.new("API failure"))
        allow(Rails.logger).to receive(:error)
      end

      it "returns nil and logs the error" do
        generator = described_class.new(survey)
        expect(generator.call).to be_nil
        expect(Rails.logger).to have_received(:error).with(/Survey Context Generation failed: API failure/)
      end
    end
  end
end
