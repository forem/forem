require "rails_helper"

RSpec.describe Ai::ContentModerationLabeler, type: :service do
  let(:user) { create(:user, :trusted) }
  let(:article) { create(:article, user: user) }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
    allow(Settings::RateLimit).to receive(:expanded_content_advisement_spec).and_return(nil)
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

      it "still allows very_good and great labels in the prompt when the article has a negative score" do
        allow(article).to receive(:status?).and_return(true)
        labeler = described_class.new(article)
        prompt = labeler.__send__(:build_prompt)
        expect(prompt).to include("This article is a \"status\" post")
        expect(prompt).to include("very_good_and_on_topic")
        expect(prompt).to include("great_and_on_topic")
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
        expect(prompt).to include("Assign `great_and_on_topic`")
        expect(prompt).to include("Assign `very_good_and_on_topic`")
      end

      it "includes linked article context in the prompt when the status embeds an internal article" do
        linked = create(:article, user: user, title: "Deep Dive into React 19")
        internal_url = URL.url(linked.path)
        status_article = create(:article, user: user)
        status_article.update_columns(
          type_of: Article.type_ofs[:status],
          title: "Interesting benchmark showing how Zustand handles 1,000 rows in React 19 #{internal_url}",
          body_markdown: "{% embed #{internal_url} minimal %}",
        )

        labeler = described_class.new(status_article)
        prompt = labeler.__send__(:build_prompt)

        expect(prompt).to include("Linked Article: \"Deep Dive into React 19\" by @#{user.username}")
        expect(prompt).to include("Linked Article Excerpt:")
      end

      it "does not attach local article details when an external URL shares a local path" do
        linked = create(:article, user: user, title: "Deep Dive into React 19")
        external_url = "https://external.example#{linked.path}"
        status_article = create(:article, user: user)
        status_article.update_columns(
          type_of: Article.type_ofs[:status],
          title: "Interesting post #{external_url}",
          body_markdown: "{% embed #{external_url} minimal %}",
        )

        labeler = described_class.new(status_article)
        prompt = labeler.__send__(:build_prompt)

        expect(prompt).not_to include("Linked Article: \"Deep Dive into React 19\"")
        expect(prompt).to include("Linked URL(s): #{external_url}")
      end
    end

    context "when article has no subforem_id or a legacy subforem without a spec and default subforem exists" do
      it "falls back to Subforem.cached_default_id for community_description when subforem_id is nil" do
        allow(article).to receive(:subforem_id).and_return(nil)
        allow(Subforem).to receive(:cached_default_id).and_return(1)
        allow(Settings::RateLimit).to receive(:internal_content_description_spec)
          .with(subforem_id: 1).and_return("DEV default community spec.")

        labeler = described_class.new(article)
        expect(labeler.__send__(:community_description)).to eq("DEV default community spec.")
      end

      it "falls back to Subforem.cached_default_id when article has a legacy subforem_id with no spec" do
        allow(article).to receive(:subforem_id).and_return(12)
        allow(Subforem).to receive(:cached_default_id).and_return(1)
        allow(Settings::RateLimit).to receive(:internal_content_description_spec)
          .with(subforem_id: 12).and_return(nil)
        allow(Settings::Community).to receive(:community_description)
          .with(subforem_id: 12).and_return(nil)
        allow(Settings::RateLimit).to receive(:internal_content_description_spec)
          .with(subforem_id: 1).and_return("DEV default community spec.")

        labeler = described_class.new(article)
        expect(labeler.__send__(:community_description)).to eq("DEV default community spec.")
      end

      it "includes expanded_content_advisement_spec from the default subforem in the prompt" do
        allow(article).to receive(:subforem_id).and_return(nil)
        allow(Subforem).to receive(:cached_default_id).and_return(1)
        allow(Settings::RateLimit).to receive(:expanded_content_advisement_spec)
          .with(subforem_id: 1).and_return("The DEV Content Playbook: reward bite-sized brilliance.")

        labeler = described_class.new(article)
        prompt = labeler.__send__(:build_prompt)
        expect(prompt).to include("**Community Content Advisement & Quality Playbook:**")
        expect(prompt).to include("The DEV Content Playbook: reward bite-sized brilliance.")
      end

      it "omits offtopic_for_subforem labels from prompt and normalizes them to likely_low_quality when multiple subforems are disabled" do
        allow(Subforem).to receive(:multiple_subforems_enabled?).and_return(false)
        allow(ai_client).to receive(:call).and_return(
          '{"moderation_label": "ok_but_offtopic_for_subforem", "compellingness_score": 0.4}',
        )

        labeler = described_class.new(article)
        prompt = labeler.__send__(:build_prompt)
        expect(prompt).not_to include("ok_but_offtopic_for_subforem")
        expect(prompt).not_to include("very_good_but_offtopic_for_subforem")
        expect(prompt).not_to include("great_but_off_topic_for_subforem")
        expect(labeler.evaluate).to eq({ label: "likely_low_quality", compellingness_score: 0.4 })
      end

      it "includes offtopic_for_subforem labels when multiple subforems are enabled" do
        allow(Subforem).to receive(:multiple_subforems_enabled?).and_return(true)
        allow(ai_client).to receive(:call).and_return(
          '{"moderation_label": "ok_but_offtopic_for_subforem", "compellingness_score": 0.4}',
        )

        labeler = described_class.new(article)
        prompt = labeler.__send__(:build_prompt)
        expect(prompt).to include("ok_but_offtopic_for_subforem")
        expect(labeler.evaluate).to eq({ label: "ok_but_offtopic_for_subforem", compellingness_score: 0.4 })
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
      on_topic_q = requests.first[:questions][:on_topic].to_s
      expect(on_topic_q).to include("developer career/job search")
      expect(on_topic_q).to include("developer productivity")
      expect(on_topic_q).to include("completely unrelated to software, technology, or developer life")
    end

    it "labels acceptable on-topic content" do
      expect(evaluate_with({})).to eq(label: "okay_and_on_topic", compellingness_score: 0.0)
    end

    it "maps calibrated quality tiers to on-topic labels when multiple subforems are disabled (default)" do
      allow(Subforem).to receive(:multiple_subforems_enabled?).and_return(false)

      # Calibrated quality tiers: >= 2.35 is very_good, >= 3.3 is great
      expect(evaluate_with(quality: 2.34)[:label]).to eq("okay_and_on_topic")
      expect(evaluate_with(quality: 2.35)[:label]).to eq("very_good_and_on_topic")
      expect(evaluate_with(quality: 3.29)[:label]).to eq("very_good_and_on_topic")
      expect(evaluate_with(quality: 3.3)[:label]).to eq("great_and_on_topic")
      expect(evaluate_with(quality: 3.8)[:label]).to eq("great_and_on_topic")
      expect(evaluate_with(quality: 1.0)[:label]).to eq("likely_low_quality")
      expect(evaluate_with(quality: 0.2)[:label]).to eq("clear_and_obvious_low_quality")
    end

    it "maps single-subforem relevance and off-topic thresholds to labels" do
      allow(Subforem).to receive(:multiple_subforems_enabled?).and_return(false)

      # Single-subforem on-topic threshold (0.30): developer career/lifestyle posts (0.30-0.50) are on-topic
      expect(evaluate_with(quality: 2.0, on_topic: 0.30)[:label]).to eq("okay_and_on_topic")
      expect(evaluate_with(quality: 2.0, on_topic: 0.35)[:label]).to eq("okay_and_on_topic")
      expect(evaluate_with(quality: 3.8, on_topic: 0.35)[:label]).to eq("great_and_on_topic")

      # Off-topic content in single-subforem mode is mapped to low-quality tiers
      expect(evaluate_with(quality: 2.0, on_topic: 0.29)[:label]).to eq("likely_low_quality")
      expect(evaluate_with(quality: 3.8, on_topic: 0.2)[:label]).to eq("likely_low_quality")
      expect(evaluate_with(quality: 2.0, on_topic: 0.15)[:label]).to eq("clear_and_obvious_low_quality")
      expect(evaluate_with(quality: 2.0, on_topic: 0.1)[:label]).to eq("clear_and_obvious_low_quality")
    end

    it "maps off-topic quality to *_offtopic_for_subforem labels when multiple subforems are enabled" do
      allow(Subforem).to receive(:multiple_subforems_enabled?).and_return(true)

      expect(evaluate_with(quality: 3.8, on_topic: 0.35)[:label]).to eq("great_but_off_topic_for_subforem")
      expect(evaluate_with(quality: 3.2, on_topic: 0.2)[:label]).to eq("very_good_but_offtopic_for_subforem")
      expect(evaluate_with(quality: 2.0, on_topic: 0.2)[:label]).to eq("ok_but_offtopic_for_subforem")
      expect(evaluate_with(quality: 3.8, on_topic: 0.6)[:label]).to eq("great_and_on_topic")
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

    it "allows negatively scored articles to earn very_good or great tiers when quality merits it" do
      article.update_column(:score, -5)

      expect(evaluate_with(quality: 4.0)[:label]).to eq("great_and_on_topic")
      expect(evaluate_with(quality: 3.0)[:label]).to eq("very_good_and_on_topic")
    end

    it "caps quality when tag moderation rules are clearly broken" do
      article.tags << create(:tag, name: "jevrules", moderation_instructions: "Posts must include a demo link.")

      expect(evaluate_with(quality: 4.0, violates_tag_rules: 0.9)[:label]).to eq("likely_low_quality")
    end

    it "composes compellingness from weighted dimensions" do
      result = evaluate_with(originality: 3.0, personal_voice: 3.0, discussion_potential: 0.0)

      expect(result[:compellingness_score]).to eq(0.7)
    end

    context "when article is a status post (quickie)" do
      let(:linked_article) do
        create(:article, user: user, title: "How Agentic Video Editing Works")
      end
      let(:status_article) do
        internal_url = URL.url(linked_article.path)
        post = create(:article, user: user)
        post.update_columns(
          type_of: Article.type_ofs[:status],
          title: "Anthropic had an agent edit its own launch video—the edit was text #{internal_url}",
          body_markdown: "{% embed #{internal_url} minimal %}",
        )
        post
      end

      def evaluate_status_with(answers)
        stub_jev({ on_topic: 0.9, quality: 2.0 }.merge(answers))
        described_class.new(status_article).evaluate
      end

      it "includes linked_article context and status-calibrated questions in the Jev request" do
        requests = stub_jev(on_topic: 0.9, quality: 2.5)

        described_class.new(status_article).evaluate

        expect(requests.size).to eq(1)
        article_state = requests.first[:state][:article]
        expect(article_state[:format]).to include("status post (quickie)")
        expect(article_state[:linked_article]).to include(
          title: "How Agentic Video Editing Works",
          author: "@#{user.username}",
        )
        expect(requests.first[:questions][:quality].to_s).to include("short status post")
      end

      it "calibrates quality tiers for status posts while keeping low-quality filtering strict" do
        expect(evaluate_status_with(quality: 2.3)[:label]).to eq("very_good_and_on_topic")
        expect(evaluate_status_with(quality: 3.2)[:label]).to eq("great_and_on_topic")
        expect(evaluate_status_with(quality: 1.8)[:label]).to eq("okay_and_on_topic")
        expect(evaluate_status_with(quality: 1.0)[:label]).to eq("likely_low_quality")
        expect(evaluate_status_with(quality: 0.2)[:label]).to eq("clear_and_obvious_low_quality")
      end
    end

    context "when TypeSafe fails" do
      let(:jev_client) { instance_double(Ai::TypeSafe::Client) }

      before do
        allow(Ai::TypeSafe::Client).to receive(:new).and_return(jev_client)
        allow(jev_client).to receive(:evaluate).and_raise(Ai::TypeSafe::Client::Error, "overloaded")
      end

      it "falls back to the safe default when Gemini API key is not present" do
        stub_const("Ai::Base::DEFAULT_KEY", nil)
        expect(described_class.new(article).evaluate).to eq(label: "no_moderation_label", compellingness_score: 0.0)
      end

      it "falls back to Gemini when Gemini API key is configured" do
        stub_const("Ai::Base::DEFAULT_KEY", "dummy_gemini_key")
        allow(ai_client).to receive(:call)
          .and_return('{"moderation_label": "very_good_and_on_topic", "compellingness_score": 0.8}')

        result = described_class.new(article).evaluate
        expect(result).to eq(label: "very_good_and_on_topic", compellingness_score: 0.8)
        expect(Ai::Base).to have_received(:new).with(hash_including(model: Ai::Base::DEFAULT_MODEL))
        expect(ai_client).to have_received(:call)
      end

      it "uses the lite Gemini model when falling back for a negatively scored article" do
        stub_const("Ai::Base::DEFAULT_KEY", "dummy_gemini_key")
        allow(article).to receive(:score).and_return(-5)
        allow(ai_client).to receive(:call)
          .and_return('{"moderation_label": "okay_and_on_topic", "compellingness_score": 0.5}')

        result = described_class.new(article).evaluate
        expect(result).to eq(label: "okay_and_on_topic", compellingness_score: 0.5)
        expect(Ai::Base).to have_received(:new).with(hash_including(model: Ai::Base::DEFAULT_LITE_MODEL))
        expect(ai_client).to have_received(:call)
      end

      it "falls back to safe default if Gemini fallback also fails" do
        stub_const("Ai::Base::DEFAULT_KEY", "dummy_gemini_key")
        allow(ai_client).to receive(:call).and_raise(StandardError, "Gemini timeout")

        result = described_class.new(article).evaluate
        expect(result).to eq(label: "no_moderation_label", compellingness_score: 0.0)
      end
    end
  end
end
