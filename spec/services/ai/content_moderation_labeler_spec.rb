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

    context "when article has tags with custom moderation instructions" do
      let(:tag_with_instructions) { create(:tag, name: "testtag", moderation_instructions: "Assure it does not contain spoilers.") }

      before do
        article.tags << tag_with_instructions
        allow(ai_client).to receive(:call).and_return('{"moderation_label": "okay_and_on_topic", "compellingness_score": 0.85}')
      end

      it "includes the custom moderation instructions in the prompt" do
        labeler = described_class.new(article)
        prompt = labeler.send(:build_prompt)
        expect(prompt).to include("**Custom Tag Moderation Instructions:**")
        expect(prompt).to include("- #testtag: Assure it does not contain spoilers.")
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

  describe "#evaluate with Jev selected" do
    before { enable_jev_for(:content_moderation) }

    # Quality Score positions run 0-4; compellingness dimensions 0-3.
    def evaluate_with(answers)
      stub_jev({ on_topic: 0.9, quality: 2.0 }.merge(answers))
      described_class.new(article).evaluate
    end

    it "decomposes the judgment into one batched request instead of calling Gemini" do
      requests = stub_jev(on_topic: 0.9, quality: 2.0)

      described_class.new(article).evaluate

      expect(Ai::Base).not_to have_received(:new)
      expect(requests.size).to eq(1)
      expect(requests.first[:questions].keys).to include(
        :harmful, :inciting, :promotional_spam, :malicious, :auto_generated, :quality, :on_topic,
        :originality, :personal_voice, :discussion_potential
      )
    end

    it "labels acceptable on-topic content" do
      expect(evaluate_with({})).to eq(label: "okay_and_on_topic", compellingness_score: 0.0)
    end

    it "maps quality and relevance to the label" do
      expect(evaluate_with(quality: 3.2)[:label]).to eq("very_good_and_on_topic")
      expect(evaluate_with(quality: 3.8)[:label]).to eq("great_and_on_topic")
      expect(evaluate_with(quality: 3.8, on_topic: 0.2)[:label]).to eq("great_but_off_topic_for_subforem")
      expect(evaluate_with(quality: 2.0, on_topic: 0.2)[:label]).to eq("ok_but_offtopic_for_subforem")
      expect(evaluate_with(quality: 1.0)[:label]).to eq("likely_low_quality")
      expect(evaluate_with(quality: 0.2)[:label]).to eq("clear_and_obvious_low_quality")
    end

    it "puts safety ahead of spam, and spam ahead of quality" do
      expect(evaluate_with(harmful: 0.9, promotional_spam: 0.95, quality: 4.0)[:label])
        .to eq("clear_and_obvious_harmful")
      expect(evaluate_with(inciting: 0.7)[:label]).to eq("likely_inciting")
      expect(evaluate_with(promotional_spam: 0.9, quality: 4.0)[:label]).to eq("clear_and_obvious_spam")
      expect(evaluate_with(malicious: 0.65)[:label]).to eq("likely_spam")
    end

    it "treats generic text as spam only when it is also promotional" do
      expect(evaluate_with(auto_generated: 0.95)[:label]).to eq("okay_and_on_topic")
      expect(evaluate_with(auto_generated: 0.95, promotional_spam: 0.55)[:label]).to eq("clear_and_obvious_spam")
    end

    it "caps negatively scored articles below the very good tiers" do
      article.update_column(:score, -5)

      expect(evaluate_with(quality: 4.0)[:label]).to eq("okay_and_on_topic")
    end

    it "caps quality when tag moderation rules are clearly broken" do
      article.tags << create(:tag, name: "jevrules", moderation_instructions: "Posts must include a demo link.")

      expect(evaluate_with(quality: 4.0, violates_tag_rules: 0.9)[:label]).to eq("likely_low_quality")
    end

    it "composes compellingness from weighted dimensions" do
      result = evaluate_with(originality: 3.0, personal_voice: 3.0, discussion_potential: 0.0)

      expect(result[:compellingness_score]).to eq(0.7)
    end

    it "falls back to the safe default when TypeSafe fails" do
      client = instance_double(Ai::TypeSafe::Client)
      allow(Ai::TypeSafe::Client).to receive(:new).and_return(client)
      allow(client).to receive(:evaluate).and_raise(Ai::TypeSafe::Client::Error, "overloaded")

      expect(described_class.new(article).evaluate).to eq(label: "no_moderation_label", compellingness_score: 0.0)
    end
  end
end
