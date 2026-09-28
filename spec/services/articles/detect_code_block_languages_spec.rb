require "rails_helper"

RSpec.describe Articles::DetectCodeBlockLanguages, type: :service do
  let(:article) { create(:published_article, title: "Code block article", body_markdown: markdown) }
  let(:ai_client) { instance_double(Ai::Base) }
  let(:service) { described_class.new(article, ai_client: ai_client) }

  describe ".contains_unlabeled_code_blocks?" do
    it "returns true when a fenced code block has no language" do
      expect(described_class.contains_unlabeled_code_blocks?("```\nputs :hi\n```")).to be(true)
    end

    it "returns false when all fenced code blocks already have languages" do
      expect(described_class.contains_unlabeled_code_blocks?("```ruby\nputs :hi\n```")).to be(false)
    end
  end

  describe "#call" do
    let(:markdown) { "```\ndef hello\n  puts 'hi'\nend\n```" }

    before do
      allow(ai_client).to receive(:call).and_return('["ruby"]')
    end

    it "updates unlabeled code blocks with a supported language and refreshes processed_html", :aggregate_failures do
      expect(service.call).to be(true)

      article.reload
      expect(article.body_markdown).to include("```ruby")
      expect(article.processed_html).to include("highlight ruby")
    end

    it "normalizes aliases to supported highlighting tags" do
      allow(ai_client).to receive(:call).and_return('["js"]')

      service.call

      expect(article.reload.body_markdown).to include("```javascript")
    end

    it "falls back to plaintext when the AI response is not a supported highlighting choice" do
      allow(ai_client).to receive(:call).and_return('["totally-made-up"]')

      service.call

      expect(article.reload.body_markdown).to include("```plaintext")
    end

    it "updates multiple unlabeled code blocks in order", :aggregate_failures do
      article.update_column("body_markdown", "```\nputs :hi\n```\n\n```\nconst answer = 42;\n```")
      allow(ai_client).to receive(:call).and_return('["ruby", "javascript"]')

      service.call

      expect(article.reload.body_markdown).to include("```ruby\nputs :hi\n```")
      expect(article.body_markdown).to include("```javascript\nconst answer = 42;\n```")
    end

    it "does not change already-labeled code blocks" do
      article.update_column(:body_markdown, "```ruby\nputs 'hi'\n```")

      expect(service.call).to be(false)
      expect(ai_client).not_to have_received(:call)
    end

    it "uses the lite Gemini model by default" do
      stub_const("Ai::Base::DEFAULT_KEY", "fake-api-key")
      allow(Ai::Base).to receive(:new).and_return(ai_client)

      described_class.new(article).call

      expect(Ai::Base).to have_received(:new).with(
        model: Ai::Base::DEFAULT_LITE_MODEL,
        wrapper: an_instance_of(described_class),
        affected_content: article,
        affected_user: article.user,
      )
    end

    it "returns false without creating an AI client when Gemini is not configured" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)
      allow(Ai::Base).to receive(:new)

      expect(described_class.new(article).call).to be(false)
      expect(Ai::Base).not_to have_received(:new)
    end
  end

  describe "#call with Jev selected" do
    let(:markdown) { "```\ndef hello\n  puts 'hi'\nend\n```\n\nText\n\n```\nconst x = 1;\n```" }
    let(:service) { described_class.new(article) }

    before { enable_jev_for(:code_block_language_detection) }

    it "asks one Choice per unlabeled block, each block in its own state" do
      requests = stub_jev do |state|
        { language: state[:code].start_with?("def") ? ["ruby", 0.9] : ["javascript", 0.8] }
      end

      expect(service.call).to be(true)
      expect(requests.map { |request| request[:state][:code] }).to eq(["def hello\n  puts 'hi'\nend", "const x = 1;"])
      expect(requests.first[:questions][:language][:criteria]).to include("ruby" => "Ruby", "plaintext" => anything)
      expect(article.reload.body_markdown).to include("```ruby").and include("```javascript")
    end

    it "falls back to plaintext on low confidence" do
      stub_jev(language: ["ruby", 0.1])

      service.call

      expect(article.reload.body_markdown.scan("```plaintext").size).to eq(2)
    end

    it "offers every supported language as an option" do
      expect(described_class.language_criteria.keys).to match_array(described_class::SUPPORTED_LANGUAGE_TAGS)
    end

    it "runs without a Gemini key" do
      stub_const("Ai::Base::DEFAULT_KEY", nil)
      stub_jev(language: ["ruby", 0.9])

      expect(service.call).to be(true)
    end
  end
end
