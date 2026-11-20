require "rails_helper"

RSpec.describe RerenderCommentEmbedsWorker, type: :worker do
  let(:comment) { create(:comment) }
  let(:permalink) { %(href="#{URL.comment(comment)}") }

  include_examples "#enqueues_on_correct_queue", "low_priority", ["Comment", 0]

  def strip_permalink(record, link = permalink)
    record.update_column(:processed_html, record.reload.processed_html.gsub(link, ""))
  end

  def article_with(embed)
    create(:article, body_markdown: "---\ntitle: Embeds #{rand(10_000)}\npublished: true\n---\n\n#{embed}")
  end

  describe "#perform" do
    it "re-renders stale comment embeds across every record type in one chain" do
      tag_article = article_with("{% comment #{comment.id_code} %}")
      url_article = article_with("{% embed #{URL.comment(comment)} %}")
      [tag_article, url_article].each { |article| strip_permalink(article) }

      Sidekiq::Testing.inline! { described_class.perform_async("Comment", 0) }

      expect(tag_article.reload.processed_html).to include(permalink)
      expect(url_article.reload.processed_html).to include(permalink)
    end

    it "re-renders an embedding comment before the article that renders it" do
      outer = create(:comment, body_markdown: "{% comment #{comment.id_code} %}")
      article = article_with("{% comment #{outer.id_code} %}")
      strip_permalink(outer)
      strip_permalink(article)

      Sidekiq::Testing.inline! { described_class.perform_async("Comment", 0) }

      expect(outer.reload.processed_html).to include(permalink)
      expect(article.reload.processed_html).to include(permalink)
    end

    it "processes one bounded id range and schedules the next existing id" do
      stub_const("#{described_class}::RANGE_SIZE", 1)
      first, second = create_list(:comment, 2)
      refresher = instance_double(Articles::UpdateDependentEmbedsWorker, refresh_records: nil)
      allow(Articles::UpdateDependentEmbedsWorker).to receive(:new).and_return(refresher)
      allow(described_class).to receive(:perform_in)

      described_class.new.perform("Comment", first.id)

      expect(refresher).to have_received(:refresh_records).with("Comment", [])
      expect(described_class).to have_received(:perform_in).once.with(described_class::DELAY, "Comment", second.id)
    end

    it "moves on to the next record type after the last range" do
      allow(described_class).to receive(:perform_in)

      described_class.new.perform("Comment", Comment.maximum(:id).to_i + 1)

      expect(described_class).to have_received(:perform_in).once.with(described_class::DELAY, "Article", 0)
    end

    it "stops after the last record type" do
      allow(described_class).to receive(:perform_in)

      described_class.new.perform("Billboard", Billboard.maximum(:id).to_i + 1)

      expect(described_class).not_to have_received(:perform_in)
    end

    it "does not advance the chain when a refresh fails, so the range is retried first" do
      article = article_with("{% comment #{comment.id_code} %}")
      refresher = Articles::UpdateDependentEmbedsWorker.new
      allow(refresher).to receive(:refresh_article).and_raise(StandardError, "boom")
      allow(Articles::UpdateDependentEmbedsWorker).to receive(:new).and_return(refresher)
      allow(described_class).to receive(:perform_in)

      expect { described_class.new.perform("Article", article.id) }
        .to raise_error(Articles::UpdateDependentEmbedsWorker::RefreshFailed, /Article #{article.id}/)
      expect(described_class).not_to have_received(:perform_in)
    end

    it "ignores unsupported record types" do
      allow(Articles::UpdateDependentEmbedsWorker).to receive(:new)

      described_class.new.perform("User", 0)

      expect(Articles::UpdateDependentEmbedsWorker).not_to have_received(:new)
    end
  end

  describe "retries exhausted" do
    it "continues the chain past the failed range" do
      allow(described_class).to receive(:enqueue_next)

      described_class.sidekiq_retries_exhausted_block.call({ "args" => ["Article", 10] }, StandardError.new("boom"))

      expect(described_class).to have_received(:enqueue_next).with("Article", 10 + described_class::RANGE_SIZE)
    end
  end
end
