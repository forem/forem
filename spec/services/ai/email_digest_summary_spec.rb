require "rails_helper"

RSpec.describe Ai::EmailDigestSummary, type: :service do
  let(:articles) do
    [
      instance_double(Article, id: 1, title: "Title 1", path: "/path1", description: "Desc 1", cached_tag_list: "ruby",
                               comments_count: 0),
      instance_double(Article, id: 2, title: "Title 2", path: "/path2", description: "Desc 2",
                               cached_tag_list: "rails", comments_count: 0),
    ]
  end
  let(:ai_client) { instance_double(Ai::Base) }
  let(:service) { described_class.new(articles, ai_client: ai_client) }

  describe "#generate" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      allow(ai_client).to receive(:call).and_return("AI generated summary")
      Rails.cache.clear
    end

    it "generates a summary using AI" do
      result = service.generate
      expect(result).to eq("AI generated summary")
      expect(ai_client).to have_received(:call).once
    end

    it "caches the result" do
      service.generate
      service.generate
      expect(ai_client).to have_received(:call).once
    end

    it "is order-independent for caching" do
      service.generate

      reordered_articles = articles.reverse
      new_service = described_class.new(reordered_articles, ai_client: ai_client)
      new_service.generate

      expect(ai_client).to have_received(:call).once
    end

    it "depends on article paths for caching" do
      service.generate

      # Same ID, different path
      modified_articles = [
        instance_double(Article, id: 1, path: "/different_path", title: "Title 1", description: "Desc 1",
                                 cached_tag_list: "ruby", comments_count: 0),
        instance_double(Article, id: 2, path: "/path2", title: "Title 2", description: "Desc 2",
                                 cached_tag_list: "rails", comments_count: 0),
      ]
      new_service = described_class.new(modified_articles, ai_client: ai_client)
      new_service.generate

      expect(ai_client).to have_received(:call).twice
    end

    it "returns nil if articles are empty" do
      empty_service = described_class.new([])
      expect(empty_service.generate).to be_nil
    end

    it "returns nil and logs error if AI client fails" do
      allow(ai_client).to receive(:call).and_raise(StandardError, "AI Error")
      expect(Rails.logger).to receive(:error).with(/AI Digest Summary generation failed/)

      expect(service.generate).to be_nil
    end

    context "with validation and retry" do
      it "returns output if valid markdown" do
        valid_output = "This is **valid** markdown."
        allow(ai_client).to receive(:call).and_return(valid_output)
        
        expect(service.generate).to eq(valid_output)
        expect(ai_client).to have_received(:call).once
      end

      it "retries once if output contains HTML" do
        invalid_output = "<p>Invalid HTML</p>"
        valid_output = "Valid **Markdown**"
        
        # First call returns invalid, second returns valid
        allow(ai_client).to receive(:call).and_return(invalid_output, valid_output)

        expect(service.generate).to eq(valid_output)
        expect(ai_client).to have_received(:call).twice
      end

      it "retries once if output contains malformed links with HTML" do
        invalid_output = "[Text](<a href='...'>)"
        valid_output = "Valid **Markdown**"
        
        allow(ai_client).to receive(:call).and_return(invalid_output, valid_output)

        expect(service.generate).to eq(valid_output)
        expect(ai_client).to have_received(:call).twice
      end

      it "returns nil and logs error if retry also fails" do
        invalid_output = "<p>Invalid HTML</p>"
        allow(ai_client).to receive(:call).and_return(invalid_output)

        expect(Rails.logger).to receive(:warn).with(/AI Digest Summary received invalid markdown/)
        expect(Rails.logger).to receive(:error).with(/AI Digest Summary failed validation/)
        
        expect(service.generate).to be_nil
        expect(ai_client).to have_received(:call).twice
      end

      describe "validation edge cases" do
        [
          "Pure text summary",
          "**Bold**, *italic*, and [links](https://dev.to)",
          "List items:\n- One\n- Two",
          "Multiple paragraphs with\n\nDouble newline.",
          "Code snippets like `rb`",
        ].each do |valid_text|
          it "accepts valid markdown: #{valid_text.truncate(30).inspect}" do
            allow(ai_client).to receive(:call).and_return(valid_text)
            expect(service.generate).to eq(valid_text)
          end
        end

        [
          "Unexpected <br> tag",
          "A <div>wrapper</div>",
          "Link with attributes: [Test](<a href='...'>)",
          "Embedded <p>paragraph</p>",
          "Self-closing <img src='...' />",
          "Nested HTML <p><span>Text</span></p>",
        ].each do |invalid_text|
          it "rejects invalid markdown: #{invalid_text.truncate(30).inspect}" do
            # Simulate first attempt invalid, second attempt also invalid to test rejection
            allow(ai_client).to receive(:call).and_return(invalid_text)
            expect(service.generate).to be_nil
          end
        end
      end
    end
  end
end
