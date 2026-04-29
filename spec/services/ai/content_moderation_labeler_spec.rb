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

  describe "#evaluate" do
    context "when AI responds successfully" do
      before do
        allow(ai_client).to receive(:call).and_return('{"moderation_label": "okay_and_on_topic", "compellingness_score": 0.85}')
      end

      it "returns the correct label and score" do
        result = described_class.new(article).evaluate
        expect(result).to eq({ label: "okay_and_on_topic", compellingness_score: 0.85 })
      end
    end

    context "when article has a negative score" do
      before do
        allow(article).to receive(:score).and_return(-10)
        allow(ai_client).to receive(:call).and_return('{"moderation_label": "okay_and_on_topic", "compellingness_score": 0.85}')
      end

      it "uses the lite model" do
        described_class.new(article).evaluate
        expect(Ai::Base).to have_received(:new).with(
          hash_including(model: Ai::Base::DEFAULT_LITE_MODEL)
        )
      end

      it "truncates body_markdown to 2000 characters" do
        allow(article).to receive(:body_markdown).and_return("a" * 3000)
        labeler = described_class.new(article)
        prompt = labeler.send(:build_prompt)
        expect(prompt).to include("a" * 1997 + "...")
        expect(prompt).not_to include("a" * 2000)
      end

      it "omits very_good and great labels from the prompt" do
        labeler = described_class.new(article)
        prompt = labeler.send(:build_prompt)
        expect(prompt).not_to include("very_good_and_on_topic")
        expect(prompt).not_to include("great_and_on_topic")
      end
    end

    context "when article is a status" do
      before do
        allow(article).to receive(:status?).and_return(true)
        allow(ai_client).to receive(:call).and_return('{"moderation_label": "okay_and_on_topic", "compellingness_score": 0.85}')
      end

      it "includes the quickie context in the prompt" do
        labeler = described_class.new(article)
        prompt = labeler.send(:build_prompt)
        expect(prompt).to include("This article is a \"status\" post")
      end
    end

    context "when article is not a status" do
      before do
        allow(article).to receive(:status?).and_return(false)
        allow(ai_client).to receive(:call).and_return('{"moderation_label": "okay_and_on_topic", "compellingness_score": 0.85}')
      end

      it "does not include the quickie context in the prompt" do
        labeler = described_class.new(article)
        prompt = labeler.send(:build_prompt)
        expect(prompt).not_to include("This article is a \"status\" post")
      end
    end

    context "when AI responds with invalid JSON but valid text" do
      before do
        allow(ai_client).to receive(:call).and_return("I think it is very_good_and_on_topic")
      end

      it "rescues the error, extracts the label, and sets score to 0.0" do
        result = described_class.new(article).evaluate
        expect(result).to eq({ label: "very_good_and_on_topic", compellingness_score: 0.0 })
      end
    end

    context "when AI raises an error" do
      before do
        allow(ai_client).to receive(:call).and_raise(StandardError, "API Error")
      end

      it "falls back to safe default after retries" do
        result = described_class.new(article).evaluate
        expect(result).to eq({ label: "no_moderation_label", compellingness_score: 0.0 })
      end

      it "retries exactly 2 times before falling back" do
        described_class.new(article).evaluate
        expect(ai_client).to have_received(:call).exactly(3).times
      end

      it "logs retry attempts" do
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)

        described_class.new(article).evaluate

        expect(Rails.logger).to have_received(:error).with(/Content Moderation Labeling failed \(attempt 1\/3\)/)
        expect(Rails.logger).to have_received(:info).with(/Retrying content moderation labeling \(attempt 2\/3\)/)
        expect(Rails.logger).to have_received(:error).with(/Content Moderation Labeling failed \(attempt 2\/3\)/)
        expect(Rails.logger).to have_received(:info).with(/Retrying content moderation labeling \(attempt 3\/3\)/)
        expect(Rails.logger).to have_received(:error).with(/Content Moderation Labeling failed \(attempt 3\/3\)/)
        expect(Rails.logger).to have_received(:error).with(/Content Moderation Labeling failed after 3 attempts, falling back to default/)
      end
    end

    context "when AI succeeds after retries" do
      before do
        call_count = 0
        allow(ai_client).to receive(:call) do
          call_count += 1
          if call_count < 3
            raise StandardError, "Temporary API Error"
          else
            '{"moderation_label": "okay_and_on_topic", "compellingness_score": 0.99}'
          end
        end
      end

      it "returns the correct label after successful retry" do
        result = described_class.new(article).evaluate
        expect(result).to eq({ label: "okay_and_on_topic", compellingness_score: 0.99 })
      end

      it "makes exactly 3 attempts before succeeding" do
        described_class.new(article).evaluate
        expect(ai_client).to have_received(:call).exactly(3).times
      end

      it "logs retry attempts but not final fallback" do
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)

        described_class.new(article).evaluate

        expect(Rails.logger).to have_received(:error).with(/Content Moderation Labeling failed \(attempt 1\/3\)/)
        expect(Rails.logger).to have_received(:info).with(/Retrying content moderation labeling \(attempt 2\/3\)/)
        expect(Rails.logger).to have_received(:error).with(/Content Moderation Labeling failed \(attempt 2\/3\)/)
        expect(Rails.logger).to have_received(:info).with(/Retrying content moderation labeling \(attempt 3\/3\)/)
        expect(Rails.logger).not_to have_received(:error).with(/falling back to default/)
      end
    end

    context "when AI succeeds on first retry" do
      before do
        call_count = 0
        allow(ai_client).to receive(:call) do
          call_count += 1
          if call_count == 1
            raise StandardError, "Temporary API Error"
          else
            '{"moderation_label": "very_good_and_on_topic", "compellingness_score": 0.4}'
          end
        end
      end

      it "returns the correct label after first retry" do
        result = described_class.new(article).evaluate
        expect(result).to eq({ label: "very_good_and_on_topic", compellingness_score: 0.4 })
      end

      it "makes exactly 2 attempts" do
        described_class.new(article).evaluate
        expect(ai_client).to have_received(:call).exactly(2).times
      end
    end
  end
end
