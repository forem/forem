require "rails_helper"

RSpec.describe Articles::UpdateDependentEmbedsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe "#perform" do
    let(:article) { build(:article, processed_html: "original_article", body_markdown: "content") }
    let(:comment_class) do
      Class.new do
        attr_accessor :processed_html
        def is_a?(klass); false; end
        def evaluate_markdown; @processed_html = "changed_comment"; end
        def update_column(col, val); end
        def bust_cache; end
      end
    end
    let(:comment) { comment_class.new.tap { |c| c.processed_html = "original_comment" } }
    let(:source_article_id) { 100 }

    before do
      liquid_embed_relation = double("LiquidEmbedReference::Relation")
      allow(LiquidEmbedReference).to receive(:where).and_return(liquid_embed_relation)
      
      article_reference = double("LiquidEmbedReference", record: article)
      comment_reference = double("LiquidEmbedReference", record: comment)
      nil_reference = double("LiquidEmbedReference", record: nil)
      
      allow(liquid_embed_relation).to receive(:find_each)
        .and_yield(article_reference)
        .and_yield(comment_reference)
        .and_yield(nil_reference)
        
      allow(article).to receive(:evaluate_and_update_column_from_markdown) do
        article.processed_html = "changed_article"
      end
      
      
      allow(comment).to receive(:update_column)
      allow(comment).to receive(:bust_cache)
      allow(article).to receive(:async_bust)
    end

    it "queries LiquidEmbedReference successfully" do
      liquid_embed_relation = double("LiquidEmbedReference::Relation")
      allow(liquid_embed_relation).to receive(:find_each)
      expect(LiquidEmbedReference).to receive(:where)
        .with(referenced_type: ["Article", nil], referenced_id: source_article_id)
        .and_return(liquid_embed_relation)
      subject.perform(source_article_id)
    end

    it "rebuilds markdown columns directly without triggers and evaluates loops conditionally" do
      subject.perform(source_article_id)
      
      # Article
      expect(article).to have_received(:evaluate_and_update_column_from_markdown)
      expect(article).to have_received(:async_bust)
      
      
      # We cannot easily spy on the send(:evaluate_markdown) when using singleton method redefinition, but it is implicitly tested by the HTML updating
      expect(comment).to have_received(:update_column).with(:processed_html, "changed_comment")
      expect(comment).to have_received(:bust_cache)
    end
    
    it "does not trigger async_bust or cache bust if the html hasn't changed" do
      allow(article).to receive(:evaluate_and_update_column_from_markdown) do
        article.processed_html = "original_article"
      end
      
      allow(comment).to receive(:evaluate_markdown) do
        comment.processed_html = "original_comment"
      end
      
      subject.perform(source_article_id)
      
      expect(article).not_to have_received(:async_bust)
      expect(comment).not_to have_received(:update_column)
      expect(comment).not_to have_received(:bust_cache)
    end
  end
end
